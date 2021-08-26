output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.kubernetes_cluster.kube_config
  sensitive = true
}
