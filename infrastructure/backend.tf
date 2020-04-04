terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "mr8ball"

    workspaces {
      name = "hugoblog"
    }
  }
}