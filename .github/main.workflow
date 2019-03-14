workflow "GH Actions for Azure" {
  on = "push"
  resolves = [
    "Deploy app",
    "Azure Login",
  ]
}

action "Login Registry" {
  uses = "actions/docker/login@6495e70"
  env = {
    DOCKER_USERNAME = "githubactionacr"
    DOCKER_REGISTRY_URL = "githubactionacr.azurecr.io"
  }
  secrets = [
    "DOCKER_PASSWORD",
    "AZURE_SERVICE_PASSWORD",
  ]
}

action "Build container image" {
  uses = "actions/docker/cli@6495e70"
  args = "build -t githubactionacr.azurecr.io/githubactionacr ."
  needs = ["Login Registry"]
}

action "Tag image" {
  uses = "actions/docker/tag@6495e70"
  args = "githubactionacr.azurecr.io/githubactionacr githubactionacr.azurecr.io/githubactionacr"
  needs = ["Build container image"]
}

action "Push to Container Registry" {
  uses = "actions/docker/cli@6495e70"
  args = "push githubactionacr.azurecr.io/githubactionacr"
  needs = ["Tag image"]
}

action "Azure Login" {
  uses = "Azure/github-actions/login@master"
  needs = ["Push to Container Registry"]
  secrets = [
    "AZURE_SERVICE_PASSWORD",
    "AZURE_SERVICE_APP_ID",
    "AZURE_SERVICE_TENANT",
    "AZURE_SUBSCRIPTION",
  ]
}

action "Create WebApp for Container" {
  uses = "Azure/github-actions/arm@1922d68686a21f7f96e6911bd0daec0eaad0c06d"
  env = {
    AZURE_RESOURCE_GROUP = "githubactionrg"
    AZURE_TEMPLATE_LOCATION = "githubactionstemplate.json"
    AZURE_TEMPLATE_PARAM_FILE = "githubparameters.json"
  }
  needs = ["Azure Login"]
}

action "Deploy app" {
  uses = "Azure/github-actions/containerwebapp@master"
  env = {
    AZURE_APP_NAME = "ga-webapp"
    DOCKER_REGISTRY_URL = "githubactionacr.azurecr.io"
    DOCKER_USERNAME = "githubactionacr"
    CONTAINER_IMAGE_NAME = "githubactionacr"
  }
  needs = ["Create WebApp for Container"]
}
