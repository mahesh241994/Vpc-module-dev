locals {
  resource_name = "${var.project_name}-${var.environment}"
  az_names = slice(data.aws_availability_zones.available.names, 0, 2)
  safe_resource_name = lower(replace("${var.project_name}-${var.environment}", "[^a-z0-9-_. ]", "-"))
  
}
