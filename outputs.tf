# TODO: Implement define outputs for the project
output "network_id" {
  description = "作成したDockerネットワークのID"
  value       = docker_network.app_network.id
}

output "web_server_ip" {
  description = "app_network上のWebサーバーコンテナのIPv4アドレス"

  value = one([
    for network in docker_container.web_server.network_data : network.ip_address
    if network.network_name == docker_network.app_network.name
  ])
}

output "web_server_port" {
  description = "Webサーバーがホスト側に公開している外部ポート番号"
  value       = docker_container.web_server.ports[0].external
}
