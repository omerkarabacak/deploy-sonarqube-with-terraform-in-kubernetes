data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com/"
}
resource "helm_release" "nginx-ingress" {
  name  = "nginxingress"
  chart = "stable/nginx-ingress"

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }
  set {
    name  = "controller.service.NodePorts.http"
    value = "32080"
  }
  set {
    name  = "controller.service.NodePorts.https"
    value = "32443"
  }
}