provider "aws" {
  region = "eu-west-1"
}

# ==========================================
# MODULES
# ==========================================

module "network" {
  source = "../../modules/network"
}

module "ssh_key" {
  source          = "../../modules/security"
  key_name        = "Jenkins_keypair"
  public_key_path = "~/.ssh/jenkins-keypair.pub"
}

module "iam" {
  source = "../../modules/iam"
}

module "observability" {
  source = "../../modules/observability"
}

# ==========================================
# COMPUTE
# ==========================================

module "jenkins_server" {
  source        = "../../modules/compute"
  ec2_name      = "Jenkins-Controller"
  instance_type = "t3.micro"
  subnet_id     = module.network.mgmt_subnet_id
  sg_id         = module.network.jenkins_sg_id
  key_pair      = module.ssh_key.key_name 
  depends_on    = [ module.network ]
}

module "prod_server" {
  source               = "../../modules/compute"
  ec2_name             = "Production-App-Server"
  instance_type        = "t3.micro"
  subnet_id            = module.network.app_subnet_id
  sg_id                = module.network.app_sg_id
  key_pair             = module.ssh_key.key_name 
  iam_instance_profile = module.iam.app_instance_profile_name
  depends_on           = [ module.network ]
}

module "monitoring_server" {
  source        = "../../modules/compute"
  ec2_name      = "Monitoring-Server"
  instance_type = "t3.micro"
  subnet_id     = module.network.mgmt_subnet_id
  sg_id         = module.network.monitoring_sg_id
  key_pair      = module.ssh_key.key_name 
  depends_on    = [ module.network ]
}