variable "container_registry_name" {
    default = "flixtube"
}

variable "cluster_name" {
    default = "flixtube"
}

variable "dns_prefix" {
    default = "flixtube"
}

variable "resource_group_name" {
    default = "flixtube"
}

variable location {
  default = "West US"
}

variable "admin_username" {
  default = "linux_admin"
}

variable app_version { # Can't be called version! That's a reserved word.
}

variable "client_id" {

}

variable "client_secret" {

}
