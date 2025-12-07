variable "compartment_id" {
  description = "OCID from tenancy page"
  type = string
}

variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
  default     = "ap-singapore-1"
}
