variable "rg_name" {}
variable "rg_location" {}
variable "rg_tag" {
  default = {
    "tier" = "dev"
  }
}
variable "vnet_name" {}
variable "address_space" {}
variable "subnets" {
    type = map
    default = {
        "web"  = "10.0.1.0/24"
        "app"  = "10.0.2.0/24"
        "data" = "10.0.3.0/24"
    }
  
} 
variable "instances" {
    default = 2
}

variable "tags" {
    type = map
}

variable "pub_ip_name" {}

variable "gw_cidr" {

  default = ["10.0.4.0/24"]
  
}

variable "gw_subnet_name" {
  default = "gwsubnet"
}