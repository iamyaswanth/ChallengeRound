resource "azurerm_linux_virtual_machine_scale_set" "vm_ss" {
    for_each                        = local.azurerm_subnets
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
        network_security_group_id = local.subnet_id_map[each.key]

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = local.azurerm_subnets[each.key]
      }
  }   
}