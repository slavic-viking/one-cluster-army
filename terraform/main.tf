resource "digitalocean_kubernetes_cluster" "kubernetes_cluster" {
  name    = var.do_kubernetes_cluster_name
  region  = var.do_region
  version = var.do_kubernetes_version

  node_pool {
    name       = var.do_default_node_pool_name
    size       = var.do_default_node_pool_size
    auto_scale = var.do_default_node_pool_auto_scale
    min_nodes  = var.do_default_node_pool_min_nodes
    max_nodes  = var.do_default_node_pool_max_nodes
  }
}
