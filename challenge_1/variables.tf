variable "rg_name" {}
variable "rg_location" {}
variable "rg_tag" {
  default = {
    "tier" = "dev"
  }
}
variable "vnet_name" {}
variable "address_space" {}

/* variable "subnet_prefixes" {
    type    = list(string)
}

variable "subnet_names" {
    #type    = list(string)
}  */

variable "subnets" {
    type = map
    default = {
        "sn_web"  = "10.0.1.0/24"
        "sn_app"  = "10.0.2.0/24"
        "sn_data" = "10.0.3.0/24"
    }
  
} 
variable "instances" {
    default = 2
}

variable "tags" {
    type = map
}

variable "pub_ip_name" {}