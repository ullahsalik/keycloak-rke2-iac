resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.14.4"

  set {
    name  = "installCRDs"
    value = "true"
  }

  create_namespace = true
}
