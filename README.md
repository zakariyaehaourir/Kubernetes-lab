# ☸️ Kubernetes Cluster on Azure (IaC & Automation)

Ce projet a pour objectif le déploiement et l'administration automatisée d'un cluster **Kubernetes multi-nœuds auto-hébergé** (vanilla Kubernetes) sur l'infrastructure Cloud **Microsoft Azure**.

L'approche adoptée repose sur les principes **DevOps & Infrastructure as Code (IaC)**, avec une séparation stricte entre :
1. **Le provisioning de l'infrastructure Cloud** avec **Terraform**.
2. **L'automatisation et la configuration logicielle** avec **Ansible**.

---

## 📌 Sommaire
- [Vue d'ensemble de l'Architecture](#-vue-densemble-de-larchitecture)
- [Topologie Réseau & Sécurité](#-topologie-réseau--sécurité)
- [Structure du Projet](#-structure-du-projet)
- [Phase 1 : Provisioning & Configuration du Cluster](#-phase-1--provisioning--configuration-du-cluster)
  - [1. Provisioning IaaS avec Terraform](#1-provisioning-iaas-avec-terraform)
  - [2. Configuration & Bootstrap K8s avec Ansible](#2-configuration--bootstrap-k8s-avec-ansible)
- [Déploiement pas-à-pas (Quickstart)](#-déploiement-pas-à-pas-quickstart)
- [Vérification du Cluster](#-vérification-du-cluster)
- [Feuille de Route (Phases Suivantes)](#-feuille-de-route-phases-suivantes)

---

## 🏗️ Vue d'ensemble de l'Architecture

L'infrastructure actuelle se compose de **3 machines virtuelles** sous Ubuntu 24.04 LTS hébergées sur Azure dans la région `polandcentral` :

| Rôle | Nom VM | IP Privée | IP Publique | Taille Azure | Rôle K8s |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Control Plane** | `control-plane` | `10.0.1.4` | **Oui** (IP Statique) | `Standard_B2als_v2` | Master / API Server / Bastion SSH |
| **Worker Node 1** | `worker-1` | `10.0.1.5` | Non (Subnet privé) | `Standard_B2als_v2` | Nœud de travail (Workloads) |
| **Worker Node 2** | `worker-2` | `10.0.1.6` | Non (Subnet privé) | `Standard_B2als_v2` | Nœud de travail (Workloads) |

---

## 🌐 Topologie Réseau & Sécurité

```text
               [ Machine d'administration locale ]
                               |
                        SSH (Port 22)
                               v
+----------------------- Azure VNet (10.0.0.0/16) -------------------------+
|                                                                          |
|  [ NSG: nsg-shared ] -> Règle entrante : Port 22 (SSH) uniquement        |
|                                                                          |
|  +------------------ Subnet Privé (10.0.1.0/24) ----------------------+  |
|  |                                                                    |  |
|  |  +-------------------------+                                       |  |
|  |  |      control-plane      | <=== Public IP (pip-k8s-master)       |  |
|  |  |        10.0.1.4         |      (Sert de Bastion / ProxyJump)    |  |
|  |  +-------------------------+                                       |  |
|  |          |               |                                         |  |
|  |     ProxyJump (SSH)  ProxyJump (SSH)                               |  |
|  |          v               v                                         |  |
|  |  +---------------+  +---------------+                              |  |
|  |  |   worker-1    |  |   worker-2    |                              |  |
|  |  |   10.0.1.5    |  |   10.0.1.6    |                              |  |
|  |  +---------------+  +---------------+                              |  |
|  |                                                                    |  |
|  |  Pods Network (Flannel CNI) : 10.244.0.0/16                        |  |
|  +--------------------------------------------------------------------+  |
+--------------------------------------------------------------------------+
```

### Principes de sécurité appliqués :
- **Surface d'attaque minimale** : Seul le `control-plane` possède une adresse IP publique. Les deux nœuds workers n'ont aucune IP publique et résident exclusivement dans le sous-réseau privé.
- **Filtrage NSG (Network Security Group)** : Le NSG `nsg-shared` n'autorise que le trafic **SSH (port 22)** entrant depuis l'extérieur.
- **Accès Bastion / ProxyJump** : L'administration et le provisioning Ansible des workers s'effectuent via un rebond SSH automatique (`ProxyJump`) à travers le `control-plane`.

---

## 📂 Structure du Projet

```text
.
├── IaC-provisionement/           # Provisioning de l'infrastructure Azure (Terraform)
│   ├── provider.tf               # Provider AzureRM
│   ├── variables.tf              # Déclaration des variables (VNet, CIDR, VMs, specs)
│   ├── main.tf                   # Resource Group global
│   ├── network.tf                # VNet, Subnet, Public IP, NSG association
│   ├── security.tf               # Règles NSG (port 22 SSH)
│   ├── compute.tf                # Interfaces réseau (NIC) et VMs Linux
│   └── outputs.tf                # Sorties (IPs privées, IP publique du master)
│
├── IaC-configuration/            # Automatisation logicielle & K8s (Ansible)
│   ├── ansible.cfg               # Configuration Ansible
│   ├── inventory.ini             # Inventaire dynamique/statique des machines
│   ├── group_vars/
│   │   ├── all/                  # Variables globales (version K8s, CIDR Pods, user)
│   │   └── workers.yml           # Configuration SSH ProxyJump pour les workers
│   ├── playbooks/
│   │   ├── main.yaml             # Préparation commune OS + Runtime containerd + K8s
│   │   ├── control_plane.yml     # Initialisation du Control Plane (kubeadm init)
│   │   ├── network.yml           # Déploiement du CNI Flannel
│   │   └── worker.yml            # Jonction des workers (kubeadm join) & labellisation
│   └── roles/
│       ├── osinit/               # Modules noyau (overlay, br_netfilter), sysctl
│       ├── containerd/           # Runtime CRI containerd + cgroup driver systemd
│       ├── kubernetes_common/    # Dépôts officiels pkgs.k8s.io, kubelet, kubeadm
│       ├── control_plane/        # Installation kubectl et bootstrap cluster
│       └── flannel/              # Application du manifeste CNI Pod Network Flannel
└── README.md
```

---

## 🚀 Phase 1 : Provisioning & Configuration du Cluster

### 1. Provisioning IaaS avec Terraform

Le répertoire `IaC-provisionement` automatise le déploiement de toutes les briques Cloud :
- **Resource Group** : `rg-k8s-lab`
- **Réseau Virtuel (VNet)** : Espace d'adressage `10.0.0.0/16`
- **Subnet** : `10.0.1.0/24` rattaché au VNet
- **IP Publique Statique** : Rattachée à la carte réseau (`nic-0`) du `control-plane`
- **Network Security Group** : Règle entrante autorisant uniquement le port 22 TCP (SSH)
- **3 Machines Virtuelles Linux** créées dynamiquement avec injection des clés SSH publiques administratives.


---

### 2. Configuration & Bootstrap K8s avec Ansible

Le répertoire `IaC-configuration` pilote la configuration simultanée et ordonnancée des nœuds :

#### A. Rebond SSH transparent (ProxyJump)
Pour atteindre les nœuds workers sans les exposer publiquement, Ansible utilise `ProxyJump` à travers le `control-plane` :


#### B. Les Rôles Ansible Développés
- **`osinit`** : 
  - Activation persistante des modules noyau requis : `overlay` et `br_netfilter`.
  - Configuration `sysctl` (`net.ipv4.ip_forward = 1`, bridge netfilter).
- **`containerd`** :
  - Installation du runtime CRI containerd.
  - Configuration du pilote cgroup vers **systemd** (`SystemdCgroup = true`).
- **`kubernetes_common`** :
  - Ajout du keyring et du dépôt APT officiel Kubernetes (`pkgs.k8s.io`).
  - Installation de `kubeadm` et `kubelet`.
  - Blocage des mises à jour automatiques via `apt-mark hold`.
- **`control_plane`** :
  - Installation de `kubectl`.
  - Initialisation du cluster via `kubeadm init` avec le CIDR Pods et l'adresse IP privée d'écoute.
- **`flannel`** :
  - Déploiement du plugin réseau de pods (CNI) via le manifeste officiel Flannel (`10.244.0.0/16`).
  - Attente du déploiement complet du `DaemonSet`.

#### C. Automatisation de l'adhésion des Workers
Le playbook `playbooks/worker.yml` :
1. Génère dynamiquement une commande de join temporaire sur le master (`kubeadm token create --print-join-command`).
2. Exécute la commande sur chaque nœud worker via Ansible.
3. Applique automatiquement le label Kubernetes `node-role.kubernetes.io/worker=` aux workers.

---
