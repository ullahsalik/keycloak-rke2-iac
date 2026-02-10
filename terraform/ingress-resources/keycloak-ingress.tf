resource "kubernetes_ingress_v1" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = "keycloak"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "keycloak.local"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "keycloak"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

