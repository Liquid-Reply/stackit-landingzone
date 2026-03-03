resource "stackit_dns_zone" "this" {
  project_id    = var.project_id
  name          = var.zone_name
  dns_name      = var.dns_name
  contact_email = var.contact_email
  default_ttl   = var.default_ttl
}

resource "stackit_dns_record_set" "this" {
  for_each = { for r in var.records : "${r.name}-${r.type}" => r }

  project_id = var.project_id
  zone_id    = stackit_dns_zone.this.zone_id
  name       = each.value.name
  type       = each.value.type
  ttl        = lookup(each.value, "ttl", var.default_ttl)
  records    = each.value.records
}
