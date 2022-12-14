
# 3-Tier architecture in Azure

A 3-tier architecture in azure using terraform.

### Design

3 tiers viz., web, app, data are deployed on 3 different subnets with dedicated NSGs. 
Each subnet hosts 2 VMs using a scale set. A dedicated subnet is created for application gateway 
which hosts the application gateway that points to the web backend pool.For the sake of 
simplicity there's no custom data, also the scale in policy is also not implemented.

### Terraform commands to execute

Terraform Initialize

```terraform init```

Terraform Validate

```terraform validate```

Terraform Plan

```terraform plan```

Terraform Apply

```terraform apply -auto-approve```
