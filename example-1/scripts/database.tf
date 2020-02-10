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

resource "azurerm_public_ip" "database_ip" {
    name                = "database-public-ip"
    location            = azurerm_kubernetes_cluster.cluster.location
    resource_group_name = "MC_${azurerm_resource_group.flixtube.name}_${var.cluster_name}_${azurerm_resource_group.flixtube.location}"
    allocation_method   = "Static"
}

output "database_ip_output" {
    value = azurerm_public_ip.database_ip.ip_address
}

resource "kubernetes_service" "database" {
    metadata {
        name = "database"
    }

    spec {
        selector = {
            pod = kubernetes_deployment.database.metadata.0.labels.pod
        }   

        session_affinity = "ClientIP"

        port {
            port        = 27017
            target_port = 27017
        }

        type             = "LoadBalancer"
        load_balancer_ip = azurerm_public_ip.database_ip.ip_address
    }
}
