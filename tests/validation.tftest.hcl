variables {
  network_driver = "host"
}

run "reject_invalid_network_driver" {
  command = plan

  expect_failures = [
    var.network_driver,
  ]
}
