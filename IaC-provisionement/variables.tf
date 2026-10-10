variable "location" {
  type        = string
  description = "Deployment Zone"
  default     = "polandcentral"
}

variable "env" {
  type        = string
  description = "Environement [dev , prod ...]"
  default     = "dev"
}
variable "project" {
  type        = string
  description = "Project Name"
  default     = "Kubernetes Learning lab"
}

variable "k8s_network_cidr" {
  type        = list(string)
  description = "The CIDR of virtuelle network (range)"
  default     = ["10.0.0.0/16"]
}

variable "vms_subnet" {
  type        = list(string)
  description = "Vms Subnet range /24"
  default     = ["10.0.1.0/24"]
}

variable "vm_instances" {
  description = "Kubernetes cluster virtual machines"
  type = map(object({
    role         = string
    size         = string
    private_ip   = string
    os_publisher = string
    os_offer     = string
    os_sku       = string
    os_version   = string
  }))
  default = {
    control-plane = {
      role       = "control-plane"
      size       = "Standard_B2als_v2"
      private_ip = "10.0.0.4"

      os_publisher = "Canonical"
      os_offer     = "ubuntu-24_04-lts"
      os_sku       = "server"
      os_version   = "latest"
    }

    worker-1 = {
      role       = "worker"
      size       = "Standard_B2als_v2"
      private_ip = "10.0.0.5"

      os_publisher = "Canonical"
      os_offer     = "ubuntu-24_04-lts"
      os_sku       = "server"
      os_version   = "latest"
    }

    worker-2 = {
      role       = "worker"
      size       = "Standard_B2als_v2"
      private_ip = "10.0.0.6"

      os_publisher = "Canonical"
      os_offer     = "ubuntu-24_04-lts"
      os_sku       = "server"
      os_version   = "latest"
    }
  }
}

variable "vm_auth_config" {
  type = object({
    username = string
    ssh_file = string
  })
  description = "Default vms user and ssh config"
  sensitive =true

  default = {
    username = "k8s-admin"
    ssh_file = "~/.ssh/id_rsa.pub"
  }
}