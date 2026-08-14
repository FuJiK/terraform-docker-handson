run "apply_infrastructure" {
  command = apply
}

run "verify_outputs" {
  command = apply

  assert {
    condition     = output.web_server_port == 8080
    error_message = "web_server_port must be 8080"
  }

  assert {
    condition     = output.network_id != ""
    error_message = "network_id must not be empty"
  }

  assert {
    condition     = can(regex("^172\\.", output.web_server_ip))
    error_message = "web_server_ip must be a private IPv4 address on app_network"
  }
}
