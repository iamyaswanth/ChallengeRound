locals{
    
    location = azurerm_resource_group.resource_group.location
    rg_name = azurerm_resource_group.resource_group.name
    depends_on = [azurerm_resource_group.resource_group]

    azurerm_subnets = {
        for subnet in azurerm_subnet.subnet :
            subnet.name => subnet.id
        }

    azurerm_subnets_list = flatten([keys(local.azurerm_subnets),keys(local.azurerm_subnets)])

    azurerm_subnets_ids_list = flatten([values(local.azurerm_subnets),values(local.azurerm_subnets)])

    azurerm_address_prefixes = {
        for subnet in azurerm_subnet.subnet :
            subnet.name => subnet.address_prefixes[0]
        }

    interfaces_list = [for index, interface in azurerm_network_interface.app_interface :  azurerm_network_interface.app_interface[index].id ]

    interfaces = flatten([local.interfaces_list, local.interfaces_list])

    avails_sets_list = tolist([ for avail_set in azurerm_availability_set.avail_set : avail_set.id ])

    avails_sets = flatten([ local.avails_sets_list, local.avails_sets_list])

}