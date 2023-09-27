# aws_iam_role.imagebuilder_instance_role
resource "aws_iam_role" "imagebuilder_instance_role" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
      Version = "2008-10-17"
    }
  )

  managed_policy_arns = ["arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  name                = "EC2ImageBuilderInstanceRole"

  tags = {
    Name = "EC2ImageBuilderInstanceRole"
  }
}

# aws_iam_instance_profile.imagebuilder_instance_profile
resource "aws_iam_instance_profile" "imagebuilder_instance_profile" {
  name = "EC2ImageBuilderInstanceProfile"
  role = aws_iam_role.imagebuilder_instance_role.name

  tags = {
    Name = "EC2ImageBuilderInstanceProfile"
  }
}
