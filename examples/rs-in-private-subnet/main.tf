locals {
    name              = "example"
    domain_name       = "example.com"
    mongodb_version   = "4.2"
    ami_owner         = "amazon"
    ami_name          = "amzn2-ami-hvm-*-x86_64-gp2"
    tags = {
        env = "development"
    }
}

data "aws_ami" "base" {
  most_recent = true
  owners      = [local.ami_owner]

  filter {
	name   = "name"
	values = [local.ami_name]
  }

  filter {
	name   = "root-device-type"
	values = ["ebs"]
  }

  filter {
	name   = "virtualization-type"
	values = ["hvm"]
  }
}

module "network" {
    source = "github.com/dioxic/terraform-aws-network"

    create_zone            = true
    bastion_count          = 1
    single_nat_gateway     = true
    enable_nat_gateway     = true
    name                   = local.name
    ssh_key_name           = var.ssh_key_name
    mongodb_version        = local.mongodb_version
    bastion_image_id       = data.aws_ami.base.id
    vpc_cidr               = "10.0.0.0/16"
    zone_domain            = local.domain_name
    tags                   = local.tags
}

module "replicaset" {
    source = "../../"

    zone_domain                  = local.domain_name
    mongodb_version              = local.mongodb_version
    sharded                      = false
    member_count                 = 3
    zone_id                      = module.network.zone_id
    subnet_ids                   = module.network.private_subnets
    vpc_id                       = module.network.vpc_id
    vpc_ssh_security_group_id    = module.network.bastion_security_group_id
    ssh_from_security_group_only = true
    image_id                     = data.aws_ami.base.id
    name                         = local.name
    ssh_key_name                 = var.ssh_key_name
    tags                         = local.tags
}