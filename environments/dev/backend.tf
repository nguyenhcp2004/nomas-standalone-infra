terraform {
  cloud{
    organization = "damien-claudecode"

    workspaces {
      name = "nomas-dev"
    }
  }
}
