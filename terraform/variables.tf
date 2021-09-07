variable "do_kubernetes_cluster_name" {
  type    = string
  default = "k8s-one-cluster-army"
}

variable "do_region" {
  type    = string
  default = "fra1"
}

variable "do_kubernetes_version" {
  type    = string
  default = "1.21.2-do.2"
}

variable "do_default_node_pool_name" {
  type    = string
  default = "node-pool-default"
}

variable "do_default_node_pool_size" {
  type    = string
  default = "s-2vcpu-2gb"
}

variable "do_default_node_pool_auto_scale" {
  type    = bool
  default = true
}

variable "do_default_node_pool_min_nodes" {
  type    = string
  default = "2"
}

variable "do_default_node_pool_max_nodes" {
  type    = string
  default = "4"
}
