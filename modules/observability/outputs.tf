output "instance_id" {
  value       = stackit_observability_instance.this.instance_id
  description = "Observability instance ID"
}

output "grafana_url" {
  value       = stackit_observability_instance.this.grafana_url
  description = "Grafana dashboard URL"
}
