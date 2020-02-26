data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com/"
}
resource "helm_release" "sonarqube" {
  name  = "sonarqube"
  chart = "stable/sonarqube"

  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "readinessProbe.sonarWebContext"
    value = "/sonarqube/"
  }
  set {
    name  = "livenessProbe.sonarWebContext"
    value = "/sonarqube/"
  }
  set {
    name  = "mysql.mysqlParams.useSSL"
    value = "false"
  }
  set {
    name  = "replicaCount"
    value = "3"
  }
  set {
    name  = "image.tag"
    value = "7.8-community"
  }
  set {
    name  = "postgresql.enabled"
    value = "false"
  }
  set {
    name  = "mysql.enabled"
    value = "false"
  }
  set {
    name  = "database.type"
    value = "mysql"
  }
  set {
    name  = "mysql.mysqlServer"
    value = "sonarqubedatabase-mysql"
  }
  set {
    name  = "mysql.mysqlUser"
    value = "mysqluser"
  }
  set {
    name  = "mysql.mysqlPassword"
    value = "mysqlpass"
  }
  set {
    name  = "mysql.mysqlDatabase"
    value = "mysqlsonarqubedb"
  }
}