output "projects" {
  value = {
    for k, v in module.project : k => {
      project_id  = v.project_id
      name        = v.project_name
      network_id  = v.network_id
      team        = v.team
      environment = v.environment
    }
  }
  description = "Map of all provisioned team projects"
}
