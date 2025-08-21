variable "project_id" {
  type = string
}

variable "region" {
  default = "US"
}

variable "dataset_id" {
  description = "The name of the dataset to deploy"
  type        = string
}
