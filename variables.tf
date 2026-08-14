# TODO: Implement define variables for the project
variable "network_name" {
  description = "Dockerネットワークの名前"
  type        = string
  default     = "app_network"
}

variable "network_driver" {
  description = "Dockerネットワークで使用するドライバー"
  type        = string
  default     = "bridge"

  validation {
    condition     = var.network_driver == "bridge"
    error_message = "network_driver には bridge を指定してください。"
  }
}

variable "web_server_name" {
  description = "Nginx Webサーバーコンテナの名前"
  type        = string
  default     = "web_server"
}

variable "nginx_image" {
  description = "Nginxコンテナで使用するDockerイメージ"
  type        = string
  default     = "nginx:alpine"
}

variable "web_server_internal_port" {
  description = "Nginxコンテナ内部の待受ポート"
  type        = number
  default     = 80

  validation {
    condition = (
      var.web_server_internal_port >= 1 &&
      var.web_server_internal_port <= 65535
    )
    error_message = "web_server_internal_port は1から65535の範囲で指定してください。"
  }
}

variable "web_server_external_port" {
  description = "ホスト側に公開するNginxのポート"
  type        = number
  default     = 8080

  validation {
    condition = (
      var.web_server_external_port >= 1 &&
      var.web_server_external_port <= 65535
    )
    error_message = "web_server_external_port は1から65535の範囲で指定してください。"
  }
}

variable "cache_server_name" {
  description = "Redisキャッシュコンテナの名前"
  type        = string
  default     = "cache_server"
}

variable "redis_image" {
  description = "Redisコンテナで使用するDockerイメージ"
  type        = string
  default     = "redis:alpine"
}
