terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "damien-claudecode"

    workspaces {
      name = "nomas-dev"
    }
  }
}
