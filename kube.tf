locals {
  # You have the choice of setting your Hetzner API token here or define the TF_VAR_hcloud_token env
  # within your shell, such as such: export TF_VAR_hcloud_token=xxxxxxxxxxx 
  # If you choose to define it in the shell, this can be left as is.

  # Your Hetzner token can be found in your Project > Security > API Token (Read & Write is required).
  hcloud_token = ""
}

module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }
  hcloud_token = var.hcloud_token != "" ? var.hcloud_token : local.hcloud_token

  source = "kube-hetzner/kube-hetzner/hcloud"

  # * Your ssh public key
  ssh_public_key = file("~/Nextcloud/Business/oujonny/ounu.ch/id_ed25519.pub")
  # null because private is protected with password run: ssh-add ~/Nextcloud/Business/oujonny/ounu.ch/id_ed25519
  ssh_private_key = null

  network_region = "eu-central"
  control_plane_nodepools = [
    {
      name        = "control-plane-fsn1",
      server_type = "cpx21",
      location    = "fsn1",
      labels      = [],
      taints      = [],
      count       = 1

      # Enable automatic backups via Hetzner
      backups = true

    },
  ]

  agent_nodepools = [
    {
      name        = "",
      server_type = "cp21",
      location    = "",
      labels      = [],
      taints      = [],
      count       = 0
    }
  ]

  # * LB location and type, the latter will depend on how much load you want it to handle, see https://www.hetzner.com/cloud/load-balancer
  load_balancer_type     = "lb11"
  load_balancer_location = "fsn1"

  # You can refine a base domain name to be use in this form of nodename.base_domain for setting the reserve dns inside Hetzner
  base_domain = "ounu.ch"

  ingress_controller = "nginx"
  ingress_replica_count = 1

  # this is a single node cluster
  allow_scheduling_on_control_plane = true
  automatically_upgrade_os = false

  # The cluster name
  cluster_name = "ounu-core"

  ### ADVANCED - Custom helm values for packages above (search _values if you want to located where those are mentioned upper in this file)
  # ⚠️ Inside the _values variable below are examples, up to you to find out the best helm values possible, we do not provide support for customized helm values.
  # Please understand that the indentation is very important, inside the EOTs, as those are proper yaml helm values.
  # We advise you to use the default values, and only change them if you know what you are doing!

  # Cert manager, all cert-manager helm values can be found at https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml
  # The following is an example, please note that the current indentation inside the EOT is important.
  cert_manager_values = <<EOT
installCRDs: true
replicaCount: 1
webhook:
  replicaCount: 1
cainjector:
  replicaCount: 1
  EOT
}

provider "hcloud" {
  token = var.hcloud_token != "" ? var.hcloud_token : local.hcloud_token
}

terraform {
  required_version = ">= 1.3.3"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.38.2"
    }
  }
}

output "kubeconfig" {
  value     = module.kube-hetzner.kubeconfig
  sensitive = true
}

variable "hcloud_token" {
  sensitive = true
  default   = ""
}

