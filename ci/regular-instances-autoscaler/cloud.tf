terraform {
  backend "remote" {
    organization = "rails_event_store"

    workspaces {
      name = "ci-autoscaler"
    }
  }
}
