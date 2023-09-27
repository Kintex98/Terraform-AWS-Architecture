variable "ami_specs" {
  description = "A nested map of values for the AMI"
  type = map(object({
    instance_types  = list(string)
    parent_image    = string # For a comprehensive list of parent images, visit https://us-east-1.console.aws.amazon.com/imagebuilder/home?region=us-east-1#/viewImages
    platform        = string # Whatever strings defined here will need to be replicated as an object in var.platform_specs
    target_accounts = list(string)
    target_regions  = list(string)
    }
  ))
}

variable "platform_specs" {
  description = "A nested map of values for each platform"
  type = map(object({
    components  = list(string) # For comprehensive list of component, visit, https://us-east-1.console.aws.amazon.com/imagebuilder/home?region=us-east-1#/viewComponents
    device_name = string       # /dev/xvda is recommended for Linux and /dev/sda1 is recommended for Windows
    volume_size = number
    volume_type = string
  }))
}

variable "security_group_ids" {
  description = "List of the ids of security groups desired for the EC2 instance deployed by Image Builder."
  type        = list(string)
}

variable "subnet_id" {
  description = "The id of the subnet desired for the EC2 instance deployed by Image Builder."
  type        = string
}
