data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com/"
}
resource "helm_release" "sonarqubedatabase" {
  name  = "sonarqubedatabase"
  chart = "stable/mysql"

  set {
    name  = "mysqlRootPassword"
    value = "mysqlrootpass"
  }

  set {
    name  = "mysqlUser"
    value = "mysqluser"
  }
  set {
    name  = "mysqlPassword"
    value = "mysqlpass"
  }
  set {
    name  = "mysqlDatabase"
    value = "mysqlsonarqubedb"
  }
}