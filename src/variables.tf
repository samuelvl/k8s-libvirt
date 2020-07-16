variable "DEBUG" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

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
      domain = string,
      server = string
    }),
    internal_zone = object({
      domain = string,
      server = string
    })
  })
}

# Kubernetes cluster configuration
variable "kubernetes_cluster" {
  description = "Configuration for Kubernetes cluster"
  type = object({
    num_masters     = number,
    num_workers     = number,
    version         = string,
    crio_version    = string,
    dns_server      = string,
    node_port_range = string,
    svc_network  = object({
      cidr    = string,
      gateway = string
    }),
    pod_network  = object({
      cidr    = string,
      gateway = string
    })
  })
}

# ETCD cluster configuration
variable "etcd_cluster" {
  description = "Configuration for ETCD cluster"
  type = object({
    version = string
  })
}

# Kubernetes inventory
variable "kubernetes_inventory" {
  description = "List of Kubernetes cluster nodes"
  type        = map(object({
    ip  = string,
    mac = string
  }))
}


# Load balancer specification
variable "load_balancer" {
  description = "Configuration for load balancer virtual machine"
  type = object({
    id               = string,
    base_img         = string,
    vcpu             = number,
    memory           = number,
    ha_proxy_version = string
  })
}

# Kubernetes masters specification
variable "kubernetes_master" {
  description = "Configuration for Kubernetes master virtual machine"
  type = object({
    id       = string,
    base_img = string,
    vcpu     = number,
    memory   = number
  })
}

# Kubernetes workers specification
variable "kubernetes_worker" {
  description = "Configuration for Kubernetes worker virtual machine"
  type = object({
    id       = string,
    base_img = string,
    vcpu     = number,
    memory   = number
  })
}
