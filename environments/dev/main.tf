
module "sg" {
    source = "../../modules/network"
}

module "ssh_key" {
    source          = "../../modules/security"
    key_name        = "Jenkins_keypair"
    public_key_path = "~/.ssh/jenkins-keypair.pub"
}

module "jenkins_server" {
    source        = "../../modules/compute"
    ec2_name      = "Jenkins-Controller"
    instance_type = "t3.micro"
    sg_id         = module.sg.sg_id
    key_pair      = module.ssh_key.key_name 
    depends_on    = [ module.sg ]
}

module "prod_server" {
    source        = "../../modules/compute"
    ec2_name      = "Production-App-Server"
    instance_type = "t3.micro"
    sg_id         = module.sg.sg_id
    key_pair      = module.ssh_key.key_name 
    depends_on    = [ module.sg ]
}