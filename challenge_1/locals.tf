locals{
    
    location = azurerm_resource_group.resource_group.location
    rg_name = azurerm_resource_group.resource_group.name
    depends_on = [azurerm_resource_group.resource_group]

    azurerm_subnets = {
        for subnet in azurerm_subnet.subnet :
            subnet.name => subnet.id
    }

    azurerm_address_prefixes = {
        for subnet in azurerm_subnet.subnet :
            subnet.name => subnet.address_prefixes[0]
    }

    nsg_rules = {
            Allow_HTTP_web  = {
            name                       = "Allow_HTTP"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "80"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
            network_security_group_name = "web-nsg"
        }

    Allow_HTTP_app =  {
            name                       = "Allow_HTTP"
            priority                   = 101
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "80"
            source_address_prefix      = local.azurerm_address_prefixes["web"]
            destination_address_prefix = local.azurerm_address_prefixes["app"]
            network_security_group_name = "app-nsg"
        }

    Allow_data_app  = {
            name                       = "Allow_data"
            priority                   = 102
            direction                  = "Outbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "3306"
            source_address_prefix      = local.azurerm_address_prefixes["app"]
            destination_address_prefix = local.azurerm_address_prefixes["data"]
            network_security_group_name = "app-nsg"
        }

    Allow_HTTP_data = {
            name                       = "Allow_HTTP"
            priority                   = 103
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "3306"
            source_address_prefix      = local.azurerm_address_prefixes["app"]
            destination_address_prefix = local.azurerm_address_prefixes["data"]
            network_security_group_name = "data-nsg"
        }
    Deny_All_data  = {
            name                       = "Deny_All"
            priority                   = 104
            direction                  = "Outbound"
            access                     = "Deny"
            protocol                   = "*"
            source_port_range          = "*"
            destination_port_range     = "*"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
            network_security_group_name = "data-nsg"
        }
    }

}