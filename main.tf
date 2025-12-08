terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

provider "oci" {
  region              = var.region
  auth                = "SecurityToken"
  config_file_profile = "learn-terraform"
}

resource "oci_core_vcn" "internal" {
  dns_label      = "internal"
  cidr_block     = "172.16.0.0/20"
  compartment_id = var.compartment_id
  display_name   = "My internal VCN"
}

resource "oci_core_subnet" "dev" {
  vcn_id                     = oci_core_vcn.internal.id
  cidr_block                 = "172.16.0.0/24"
  compartment_id             = var.compartment_id
  display_name               = "Develop subnet"
  prohibit_public_ip_on_vnic = false
  dns_label                  = "dev"
}

data "oci_core_images" "latest_images" {
  compartment_id   = var.compartment_id
  operating_system = "Canonical Ubuntu"

  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-24.04-Minimal-.*$"]
    regex  = true
  }

  shape      = "VM.Standard.E4.Flex"
  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

resource "oci_core_instance" "terraform-testing" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id

  shape = "VM.Standard.E3.Flex"
  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.latest_images.images[0].id
  }

  create_vnic_details {
    subnet_id = oci_core_subnet.dev.id

    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand("~/.ssh/id_rsa.pub"))
  }

  display_name = "terraform server"
}
