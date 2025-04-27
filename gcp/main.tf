module "network" {
    source = "./network"
}

module "compute" {
    source = "./compute"
    instance_name = "node1"
}