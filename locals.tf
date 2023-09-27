locals {
  
  config =yamldecode(file("./config.yml"))
  main_vpc = try(local.config["main_vpc"], {} )
  environments = try(local.main_vpc["environment"], {} )


  prod_env = try(local.environments["prod"], {} )
  prod_ec2s = try(local.prod_env["ec2"], {} )
  v4_env_offset = ceil(log(length(local.environments) + 1, 5))

  rds = try(local.prod_env["prod-db-postgres"], {} )

  prod_aws_eips = try(local.main_vpc["prod_aws_eips"], [])
}
