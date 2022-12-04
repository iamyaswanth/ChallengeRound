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

resource "azurerm_network_security_group" "all_nsg" {
  for_each = local.azurerm_subnets

  name                = "${each.key}-nsg"
  location            = local.location
  resource_group_name = local.rg_name
}

resource "azurerm_network_security_rule" "nsg_rules" {
  for_each                    = local.nsg_rules 
  name                        = each.key
  direction                   = each.value.direction
  access                      = each.value.access
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = local.rg_name
  network_security_group_name = each.value.network_security_group_name
  depends_on = [
    azurerm_network_security_group.all_nsg
  ]
}

resource "azurerm_subnet_network_security_group_association" "sn_nsg_association" {
  for_each = local.azurerm_subnets

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.all_nsg[each.key].id
  depends_on                = [
    azurerm_network_security_rule.nsg_rules
  ]
}

resource "azurerm_linux_virtual_machine_scale_set" "vm_ss" {
    for_each                        = azurerm_subnet_network_security_group_association.sn_nsg_association
    name                            = each.key
    resource_group_name             = local.rg_name
    location                        = local.location
    sku                             = "Standard_F2"
    instances                       = 2
    admin_username                  = "adminuser"
    admin_password                  = "challenge@1234"
    disable_password_authentication = false
    
    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }

    os_disk {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
    }

    network_interface {
        name    = "${each.key}-nic"
        primary = true
        network_security_group_id = each.value.network_security_group_id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = each.value.subnet_id
      application_gateway_backend_address_pool_ids = "${each.key == "web" ? "${azurerm_application_gateway.app_gateway.backend_address_pool.*.id}" : []}" 
      }
    }   
  }

# Application gateway

resource "azurerm_subnet" "gw_subnet" {

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
    rule_type          = "Basic"
    url_path_map_name  = "RoutingPath"
    http_listener_name = "gateway-listener"
    backend_address_pool_name = "pool1"
    backend_http_settings_name = "HTTPSetting"
  }

}