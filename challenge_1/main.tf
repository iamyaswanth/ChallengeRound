resource "azurerm_resource_group" "resource_group" {
  name     = var.rg_name
  location = var.rg_location
  tags     = var.rg_tag
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = var.address_space
  location            = local.location
  name                = var.vnet_name
  resource_group_name = local.rg_name
  tags                = var.tags
  depends_on          = [azurerm_resource_group.resource_group]
}

resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  address_prefixes     = [each.value]
  name                 = each.key
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  
  depends_on = [azurerm_resource_group.resource_group, azurerm_virtual_network.vnet]
} 

resource "azurerm_network_security_group" "web_nsg" {
  name                = "web_nsg"
  location            = local.location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web_nsg_association" {
  subnet_id                 = local.azurerm_subnets["snweb"]
  network_security_group_id = azurerm_network_security_group.web_nsg.id
  depends_on                = [
    azurerm_network_security_group.web_nsg
  ]
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "app_nsg"
  location            = local.location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = local.azurerm_address_prefixes["snweb"]
    destination_address_prefix = local.azurerm_address_prefixes["snapp"]
  }
  security_rule {
    name                       = "Allow_data"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = local.azurerm_address_prefixes["snapp"]
    destination_address_prefix = local.azurerm_address_prefixes["sndata"]
  }
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = local.azurerm_subnets["snapp"]
  network_security_group_id = azurerm_network_security_group.app_nsg.id
  depends_on                = [
    azurerm_network_security_group.app_nsg
  ]
}

resource "azurerm_network_security_group" "data_nsg" {
  name                = "data_nsg"
  location            = local.location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = local.azurerm_address_prefixes["snapp"]
    destination_address_prefix = local.azurerm_address_prefixes["sndata"]
  }
  security_rule {
    name                       = "Deny_All"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "data_nsg_association" {
  subnet_id                 = local.azurerm_subnets["sndata"]
  network_security_group_id = azurerm_network_security_group.data_nsg.id
  depends_on                = [azurerm_network_security_group.web_nsg]
}

resource "azurerm_network_interface" "app_interface" {
  count = (var.instances) * length(local.azurerm_subnets)

  name                = "${local.azurerm_subnets_list[count.index]}-${count.index}"
  location            = local.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.azurerm_subnets_ids_list[count.index]
    private_ip_address_allocation = "Dynamic"
  }

}

data "azurerm_network_interface" "nics" {
  count               = (var.instances) * length(local.azurerm_subnets)
  name                = "${local.azurerm_subnets_list[count.index]}-${count.index}"
  resource_group_name = local.rg_name

  depends_on = [azurerm_network_interface.app_interface]
} 

resource "azurerm_availability_set" "avail_set" {
  for_each = local.azurerm_subnets

  name                         = "${each.key}-avail-set"
  location                     = local.location
  resource_group_name          = local.rg_name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 3

}

resource "azurerm_linux_virtual_machine" "web_vm" {
  count = (var.instances) * length(local.azurerm_subnets)

  name                  = "${local.azurerm_subnets_list[count.index % 3]}-${count.index}"
  resource_group_name   = local.rg_name
  location              = local.location
  size                  = "Standard_D2s_v3"
  network_interface_ids = [data.azurerm_network_interface.nics[count.index].id]#, count.index) #[element(local.interfaces, (count.index % 3))]
  availability_set_id   = local.avails_sets[count.index % 3]

  admin_username = "adminuser"
  admin_password = "Password1234!@"

  disable_password_authentication = false

  os_disk {
    name                 = "osdisk-${local.azurerm_subnets_list[count.index % 3]}-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = var.tags
}

#Application gateway

/*resource "azurerm_subnet" "gw_subnet" {

  address_prefixes     = var.gw_cidr
  name                 = var.gw_subnet_name
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  
  depends_on = [azurerm_resource_group.resource_group, azurerm_virtual_network.vnet]
} 

resource "azurerm_public_ip" "agwpubip" {
  name                = var.pub_ip_name
  location            = local.location
  resource_group_name = local.rg_name
  allocation_method   = "Dynamic"
  tags                = var.tags
} 

resource "azurerm_application_gateway" "app_gateway" {
  name                = "app-gateway"
  resource_group_name = local.rg_name
  location            = local.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gw-ip-config"
    subnet_id = azurerm_subnet.gw_subnet.id
  }

  frontend_port {
    name = "front-end-port"
    port = 80
  }

 frontend_ip_configuration {
    name                 = "front-end-ip-config"
    public_ip_address_id = azurerm_public_ip.agwpubip.id
  }

#backendpools -- pending
  backend_address_pool{      
      name         = "pool1"
      ip_addresses = [
      "${azurerm_network_interface.app_interface1.private_ip_address}"
      ]
  }

backend_address_pool {
      name         = "pool2"
      ip_addresses = [
      "${azurerm_network_interface.app_interface2.private_ip_address}"]
  
  }

  backend_http_settings {
      name                  = "HTTPSetting"
      cookie_based_affinity = "Disabled"
      path                  = ""
      port                  = 80
      protocol              = "Http"
      request_timeout       = 60
    }

  http_listener {
      name                           = "gateway-listener"
      frontend_ip_configuration_name = "front-end-ip-config"
      frontend_port_name             = "front-end-port"
      protocol                       = "Http"
    }

# URL routing rules
 request_routing_rule {
    name               = "RoutingRuleA"
    rule_type          = "PathBasedRouting"
    url_path_map_name  = "RoutingPath"
    http_listener_name = "gateway-listener"
  }

  url_path_map {
    name                               = "RoutingPath"
    default_backend_address_pool_name  = "pool1"
    default_backend_http_settings_name = "HTTPSetting"

     path_rule {
      name                       = "pool1RoutingRule"
      backend_address_pool_name  = "pool1"
      backend_http_settings_name = "HTTPSetting"
      paths                      = [
        "/pool1/*",
      ]
    }

    path_rule {
      name                       = "pool2RoutingRule"
      backend_address_pool_name  = "pool2"
      backend_http_settings_name = "HTTPSetting"
      paths                      = [
        "/pool2/*",
      ]
    }
  }
}*/