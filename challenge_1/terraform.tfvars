rg_name = "rg_challenge"
rg_location = "East US"
vnet_name = "challenge"
address_space = ["10.0.0.0/16"]
subnets = {
        "snweb"  = "10.0.1.0/24"
        "snapp"  = "10.0.2.0/24"
        "sndata" = "10.0.3.0/24"
    } 
tags = {
    "env" = "dev"
    }
pub_ip_name = "appgw_pub_ip"