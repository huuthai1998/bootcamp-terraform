data "aws_ami" "example" {
  executable_users = ["self"]
  most_recent      = true
  owners           = ["self"]
}
