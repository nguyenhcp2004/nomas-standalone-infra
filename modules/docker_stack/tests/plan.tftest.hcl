// Terraform test for docker_stack module: plan-only with dummy SSH and compose paths.
run "plan_docker_stack_module" {
  command = plan

  variables {
    host             = "127.0.0.1"
    ssh_user         = "root"
    ssh_private_key  = "-----BEGIN RSA PRIVATE KEY-----\nMIIEpgIBAAKCAQEA..."
    compose_source   = "./tests/fixtures/docker-compose.yml"
    compose_dest     = "/tmp/docker-compose.yml"
    compose_checksum = "ea3456f3b0b4eb1234567890abcdef1234567890abcdef1234567890abcdef"
  }
}
