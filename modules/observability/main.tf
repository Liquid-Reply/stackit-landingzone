resource "stackit_observability_instance" "this" {
  project_id             = var.project_id
  name                   = var.name
  plan_name              = var.plan_name
  acl                    = var.acl
  metrics_retention_days = var.metrics_retention_days
  logs_retention_days    = var.logs_retention_days
  traces_retention_days  = var.traces_retention_days
}

resource "stackit_observability_scrapeconfig" "this" {
  for_each = { for sc in var.scrape_configs : sc.name => sc }

  project_id   = var.project_id
  instance_id  = stackit_observability_instance.this.instance_id
  name         = each.value.name
  metrics_path = each.value.metrics_path

  targets = [
    for t in each.value.targets : {
      urls   = t.urls
      labels = t.labels
    }
  ]
}
