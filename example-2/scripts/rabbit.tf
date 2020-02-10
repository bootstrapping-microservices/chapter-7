
resource "kubernetes_deployment" "rabbit" {
  metadata {
    name = "rabbit"

    labels = {
      pod = "rabbit"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        pod = "rabbit"
      }
    }

    template {
      metadata {
        labels = {
          pod = "rabbit"
        }
      }

      spec {
        container {
          image = "rabbitmq:3-management"
          name  = "rabbit"

          port {
            container_port = 5672
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "rabbit" {
    metadata {
        name = "rabbit"
    }

    spec {
        selector = {
            pod = kubernetes_deployment.rabbit.metadata.0.labels.pod
        }   

        port {
            port        = 5672
            target_port = 5672
        }
    }
}

resource "azurerm_public_ip" "rabbit_dashboard_ip" {
    name                = "rabbit-dashboard-public-ip"
    location            = azurerm_kubernetes_cluster.cluster.location
    resource_group_name = "MC_${azurerm_resource_group.flixtube.name}_${var.cluster_name}_${azurerm_resource_group.flixtube.location}"
    allocation_method   = "Static"
}

output "rabbit_dashboard_ip_output" {
    value = azurerm_public_ip.rabbit_dashboard_ip.ip_address
}

resource "kubernetes_service" "rabbit_dashboard" {
    metadata {
        name = "rabbit-dashboard"
    }

    spec {
        selector = {
            pod = kubernetes_deployment.rabbit.metadata.0.labels.pod
        }   

        session_affinity = "ClientIP"

        port {
            port        = 15672
            target_port = 15672
        }

        type             = "LoadBalancer"
        load_balancer_ip = azurerm_public_ip.rabbit_dashboard_ip.ip_address
    }
}
