locals {
    service_name = "video-streaming"
    login_server = azurerm_container_registry.container_registry.login_server
    username = azurerm_container_registry.container_registry.admin_username
    password = azurerm_container_registry.container_registry.admin_password
    image_tag = "${local.login_server}/${local.service_name}:${var.app_version}"
}

resource "null_resource" "docker_build" {

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker build -t ${local.image_tag} --file ../${local.service_name}/Dockerfile-prod ../${local.service_name}"
    }
}

resource "null_resource" "docker_login" {

    depends_on = [ null_resource.docker_build ]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker login ${local.login_server} --username ${local.username} --password ${local.password}"
    }
}

resource "null_resource" "docker_push" {

    depends_on = [ null_resource.docker_login ]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker push ${local.image_tag}"
    }
}

resource "kubernetes_deployment" "service_deployment" {

    depends_on = [ null_resource.docker_push ]

    metadata {
        name = local.service_name

    labels = {
            pod = local.service_name
        }
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                pod = local.service_name
            }
        }

        template {
            metadata {
                labels = {
                    pod = local.service_name
                }
            }

            spec {
                container {
                    image = local.image_tag
                    name  = local.service_name

                    env {
                        name = "PORT"
                        value = "80"
                    }
                }
            }
        }
    }
}

resource "azurerm_public_ip" "service_ip" {
    name                = "${local.service_name}-public-ip"
    location            = azurerm_kubernetes_cluster.cluster.location
    resource_group_name = "MC_${azurerm_resource_group.flixtube.name}_${var.cluster_name}_${azurerm_resource_group.flixtube.location}"
    allocation_method   = "Static"
}

output "service_ip_output" {
    value = azurerm_public_ip.service_ip.ip_address
}

resource "kubernetes_service" "service" {
    metadata {
        name = local.service_name
    }

    spec {
        selector = {
            pod = kubernetes_deployment.service_deployment.metadata.0.labels.pod
        }   

        session_affinity = "ClientIP"

        port {
            port        = 80
            target_port = 80
        }

        type             = "LoadBalancer"
        load_balancer_ip = azurerm_public_ip.service_ip.ip_address
    }
}
