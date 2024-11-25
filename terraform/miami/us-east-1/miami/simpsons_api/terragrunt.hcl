include "root" {
  path = find_in_parent_folders()
}

# IF the terraform was already pushed
# terraform {
#   source = "git@github.com:nicgedemer/jv-api.git//terraform/modules/jellyvision/simpsons_api"
# }

terraform {
  source = "../../../..//modules/jellyvision"
}