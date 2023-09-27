# aws_imagebuilder_image_recipe.image
resource "aws_imagebuilder_image_recipe" "image" {
  for_each = var.ami_specs

  name         = "${each.value.parent_image}-recipe"
  parent_image = "arn:aws:imagebuilder:${data.aws_region.current.name}:aws:image/${each.value.parent_image}/x.x.x"
  version      = "1.0.0"

  block_device_mapping {
    device_name = var.platform_specs[each.value.platform].device_name

    ebs {
      delete_on_termination = true
      volume_size           = var.platform_specs[each.value.platform].volume_size
      volume_type           = var.platform_specs[each.value.platform].volume_type
    }
  }

  dynamic "component" { # This will dynamically add components to each resource block depending on how many are defined in terraform.tfvars
    for_each = var.platform_specs[each.value.platform].components

    content {
      component_arn = "arn:aws:imagebuilder:${data.aws_region.current.name}:aws:component/${component.value}/x.x.x"
    }
  }

  tags = {
    Name = "${each.value.parent_image}-recipe"
  }
}

# aws_imagebuilder_infrastructure_configuration.image
resource "aws_imagebuilder_infrastructure_configuration" "image" {
  for_each = var.ami_specs

  instance_profile_name         = aws_iam_instance_profile.imagebuilder_instance_profile.name
  instance_types                = each.value.instance_types
  name                          = "${each.value.parent_image}-infra-config"
  security_group_ids            = var.security_group_ids
  subnet_id                     = var.subnet_id
  terminate_instance_on_failure = true

  resource_tags = {
    Resource = "imagebuilder"
  }

  tags = {
    Name = "${each.value.parent_image}-infra-config"
  }
}

# aws_imagebuilder_distribution_configuration.image
resource "aws_imagebuilder_distribution_configuration" "image" {
  for_each = var.ami_specs

  name = "${each.value.parent_image}-distrib-config"

  dynamic "distribution" {
    for_each = each.value.target_regions

    content {
      region = distribution.value

      ami_distribution_configuration {
        description = "A hardened and updated copy of ${each.value.parent_image}"
        name        = "${each.value.parent_image}-hardened-{{ imagebuilder:buildDate }}"

        ami_tags = {
          Name     = "${each.value.parent_image}-hardened-{{ imagebuilder:buildDate }}"
          Resource = "imagebuilder"
        }

        launch_permission {
          user_ids = each.value.target_accounts
        }
      }
    }
  }

  tags = {
    Name = "${each.value.parent_image}-distrib-config"
  }
}

# aws_imagebuilder_image_pipeline.image
resource "aws_imagebuilder_image_pipeline" "image" {
  for_each = var.ami_specs

  description                      = "Pipeline to generate the most up to date AMI based off of ${each.value.parent_image}"
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.image[each.key].arn
  image_recipe_arn                 = aws_imagebuilder_image_recipe.image[each.key].arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.image[each.key].arn
  name                             = "${each.value.parent_image}-pipeline"
  status                           = "ENABLED"

  schedule {
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
    schedule_expression                = "cron(0 0 ? * wed *)" # Every Wednesday, the pipeline will check for an updated ami/component and initialize is there is an update.
  }

  tags = {
    Name = "${each.value.parent_image}-pipeline"
  }
}
