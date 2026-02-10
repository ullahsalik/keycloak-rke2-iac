resource "helm_release" "keycloak" {
  name       = "keycloak"
  namespace  = "keycloak"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"

  values = [
    file("${path.module}/values.yaml")
  ]

  create_namespace = true
}

