# Deploys the Video streaming microservice to the Kubernetes cluster.

locals {
    service_name = "video-streaming"
    login_server = azurerm_container_registry.container_registry.login_server
    username = azurerm_container_registry.container_registry.admin_username
    password = azurerm_container_registry.container_registry.admin_password
    image_tag = "${local.login_server}/${local.service_name}:${var.app_version}"
}

# resource "null_resource" "docker_build" {

#     triggers = {
#         always_run = timestamp()
#     }

#     provisioner "local-exec" {
#         command = "docker build -t ${local.image_tag} --file ../${local.service_name}/Dockerfile-prod ../${local.service_name}"
#     }
# }

# 1. Logging into the container registry
resource "null_resource" "docker_login" {

    # depends_on = [ null_resource.docker_build ]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker login ${local.login_server} --username ${local.username} --password ${local.password}"
    }
}

# 2. Build multi-platform image and Push the image to the container registry
resource "null_resource" "docker_push" {

    depends_on = [ null_resource.docker_login ]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker buildx build --platform linux/arm64,linux/amd64 -t ${local.image_tag} --file ../${local.service_name}/Dockerfile-prod ../${local.service_name} --push"
    }
}

# 3. Authentication with the container registry
resource "kubernetes_secret" "docker_credentials" {
    metadata {
        name = "docker-credentials"
    }

    data = {
        ".dockerconfigjson" = jsonencode(local.dockercreds)
    }

    type = "kubernetes.io/dockerconfigjson"
}

# 4. Deploy video-streaming service in k8s

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

                image_pull_secrets {
                    name = kubernetes_secret.docker_credentials.metadata[0].name
                }
            }
        }
    }
}

resource "kubernetes_service" "service" {
    metadata {
        name = local.service_name
    }

    spec {
        selector = {
            pod = kubernetes_deployment.service_deployment.metadata[0].labels.pod
        }   

        session_affinity = "ClientIP"

        port {
            port        = 80
            target_port = 80
        }

        type             = "LoadBalancer"
    }
}
