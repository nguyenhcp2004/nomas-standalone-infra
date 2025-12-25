// Terraform test for vps module: plan-only with dummy inputs, backend disabled.
run "plan_vps_module" {
  command = plan

  variables {
    droplet_name = "test-vps"
    region       = "sgp1"
    size         = "s-1vcpu-1gb"
    image        = "ubuntu-22-04-x64"
    ssh_keys     = []
    user_data    = "echo hello"
    tags         = ["terraform-test"]
  }
}
