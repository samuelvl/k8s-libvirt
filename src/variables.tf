# Libvirt configuration
variable "libvirt" {
  description = "Libvirt configuration"
  type = object({
    pool      = string,
    pool_path = string
  })
}

variable "network" {
  description = "Network configuration"
  type = object({
    name    = string,
    subnet  = string,
    gateway = string
  })
}

# DNS configuration
variable "dns" {
  description = "DNS configuration"
  type = object({
    public_zone = object({
      domain = string
    }),
    internal_zone = object({
      domain = string
    })
  })
}

# Load balancer specification
variable "load_balancer" {
  description = "Configuration for load balancer virtual machine"
  type = object({
    hostname = string,
    base_img = string,
    vcpu     = number,
    memory   = number
  })
}

# Kubernetes cluster
variable "kubernetes_cluster" {
  description = "Configuration for Kubernetes cluster"
  type = object({
    num_masters = number,
    num_workers = number,
    svc_network = object({
      cidr    = string,
      gateway = string
    }),
    pod_network = object({
      cidr    = string,
      gateway = string
    })
  })
}

# Kubernetes masters specification
variable "kubernetes_master" {
  description = "Configuration for Kubernetes master virtual machine"
  type = object({
    hostname = string,
    base_img = string,
    vcpu     = number,
    memory   = number
  })
}

# Kubernetes workers specification
variable "kubernetes_worker" {
  description = "Configuration for Kubernetes worker virtual machine"
  type = object({
    hostname = string,
    base_img = string,
    vcpu     = number,
    memory   = number
  })
}
