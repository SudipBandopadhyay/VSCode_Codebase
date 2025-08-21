provider "google" {
  project = var.project_id
  region  = var.region
}

# Create dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  location   = var.region
}

# Create table from schema files
locals {
  table_schemas = fileset("${path.module}/datasets/${var.dataset_id}/tables", "*.json")
}

resource "google_bigquery_table" "tables" {
  for_each = { for file in local.table_schemas : file => file }

  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = replace(each.key, ".json", "")
  schema     = file("${path.module}/datasets/${var.dataset_id}/tables/${each.key}")
  deletion_protection = false
}

# Create views from SQL files
locals {
  view_files = fileset("${path.module}/datasets/${var.dataset_id}/views", "*.sql")
}

resource "google_bigquery_table" "views" {
  for_each = { for file in local.view_files : file => file }

  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = replace(each.key, ".sql", "")
  deletion_protection = false

  view {
    query = file("${path.module}/datasets/${var.dataset_id}/views/${each.key}")
    use_legacy_sql = false
  }
}

# Create routines (UDFs or stored procedures)
locals {
  routine_files = fileset("${path.module}/datasets/${var.dataset_id}/routines", "*.sql")
}

resource "google_bigquery_routine" "routines" {
  for_each = { for file in local.routine_files : file => file }

  dataset_id   = google_bigquery_dataset.dataset.dataset_id
  routine_id   = replace(each.key, ".sql", "")
  definition_body = file("${path.module}/datasets/${var.dataset_id}/routines/${each.key}")
  routine_type = "SCALAR_FUNCTION" # or "PROCEDURE" depending on your file

  language = "SQL"
}
