# TODO: Implement define resources for the project
resource "docker_network" "app_network" {
  name       = var.network_name
  driver     = var.network_driver
  attachable = true
}

resource "docker_image" "nginx" {
  name         = var.nginx_image
  keep_locally = true
}

resource "docker_image" "redis" {
  name         = var.redis_image
  keep_locally = true
}

resource "docker_container" "web_server" {
  name    = var.web_server_name
  image   = docker_image.nginx.image_id
  restart = "unless-stopped"

  networks_advanced {
    name    = docker_network.app_network.name
    aliases = [var.web_server_name]
  }

  ports {
    internal = var.web_server_internal_port
    external = var.web_server_external_port
    protocol = "tcp"
  }
}

resource "docker_container" "cache_server" {
  name    = var.cache_server_name
  image   = docker_image.redis.image_id
  restart = "unless-stopped"

  networks_advanced {
    name    = docker_network.app_network.name
    aliases = [var.cache_server_name]
  }
}
