resource "kubernetes_deployment" "database" {
  metadata {
    name = "database"

    labels = {
      pod = "database"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        pod = "database"
      }
    }

    template {
      metadata {
        labels = {
          pod = "database"
        }
      }

      spec {
        container {
          image = "mongo:3.4"
          name  = "database"

          port {
            container_port = 27017
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "database" {
    metadata {
        name = "database"
    }

    spec {
        selector = {
            pod = kubernetes_deployment.database.metadata[0].labels.pod
        }   

        session_affinity = "ClientIP"

        port {
            port        = 27017
            target_port = 27017
        }

        type             = "LoadBalancer"
    }
}
