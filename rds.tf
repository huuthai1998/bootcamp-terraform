resource "aws_db_instance" "bootcamp" {
  identifier             = "bootcamp123"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "15.3"
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = ["sg-082cc0efcee8ad457"]
  username               = "postgres"
  password               = "12345678"
  db_subnet_group_name = aws_db_subnet_group.default.name
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = ["subnet-04519d94985a172cc", "subnet-0933ed5932e1155d7", "subnet-0368ee10ab9aa48f5","subnet-01fda852bbec5aed5"]

  tags = {
    Name = "My DB subnet group"
  }
}