//////////////////////////////////////////////////////////////////////
////
////   AWS ACCOUNT DATA
////
///////////////////////////////////////////////////////////////////////

data "aws_caller_identity" "current" {}


//////////////////////////////////////////////////////////////////////
////
////   ACCESS CONFIGS
////
///////////////////////////////////////////////////////////////////////

resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = "${file("../../ssh-keys/deployer-key.pub")}"
}


//////////////////////////////////////////////////////////////////////
////
////   PROFILE CONFIGS
////
///////////////////////////////////////////////////////////////////////

resource "aws_iam_instance_profile" "web_server_profile" {
  name  = "WEB_SERVER_PROFILE"
  role  = "${aws_iam_role.web_server_role.name}"

  depends_on = ["aws_iam_role.web_server_role"]
}

resource "aws_iam_role" "web_server_role" {
  name = "WEB_SERVER_ROLE"
  path = "/"

  assume_role_policy = "${data.aws_iam_policy_document.web_server_role_policy.json}"

  depends_on = ["data.aws_iam_policy_document.web_server_role_policy"]
}

resource "aws_iam_role_policy_attachment" "web_server_policy_attachment" {
  role       = "${aws_iam_role.web_server_role.name}"
  policy_arn = "${aws_iam_policy.web_server_policy.arn}"

  depends_on = ["aws_iam_role.web_server_role", "aws_iam_policy.web_server_policy"]
}

resource "aws_iam_policy" "web_server_policy" {
  name        = "web_server_policy"
  path        = "/"
  description = ""

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:eu-central-1:${data.aws_caller_identity.current.account_id}:table/*"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "web_server_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


//////////////////////////////////////////////////////////////////////
////
////   NETWORKS CONFIGS
////
///////////////////////////////////////////////////////////////////////

resource "aws_vpc" "web_app_vpc" {
  cidr_block = "10.50.0.0/16"

  tags {
    Name = "WEB_APP_VPC"
  }
}

resource "aws_internet_gateway" "internet_getway" {
  vpc_id = "${aws_vpc.web_app_vpc.id}"
  tags {
    Name = "INTERNET_GETWAY/WEB_APP_VPC"
  }

  depends_on = ["aws_vpc.web_app_vpc"]
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.web_app_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_getway.id}"
  }

  tags {
    Name = "ROUTE_TABLE/WEB_APP_VPC"
  }

  depends_on = ["aws_internet_gateway.internet_getway"]
}

resource "aws_route_table_association" "route_table_association_web" {
  subnet_id      = "${aws_subnet.web_zone.id}"
  route_table_id = "${aws_route_table.route_table.id}"

  depends_on = ["aws_subnet.web_zone", "aws_route_table.route_table"]
}

resource "aws_subnet" "web_zone" {
  vpc_id     = "${aws_vpc.web_app_vpc.id}"
  cidr_block = "10.50.1.0/24"

  tags {
    Name = "WEB_ZONE/WEB_APP_VPC"
  }

  depends_on = ["aws_vpc.web_app_vpc"]
}

resource "aws_security_group" "security_group_web" {
  vpc_id = "${aws_vpc.web_app_vpc.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"] # Put your ip here like so "50.25.175.23/32"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = ["aws_vpc.web_app_vpc"]
}


//////////////////////////////////////////////////////////////////////
////
////   INSTANCES CONFIGS
////
///////////////////////////////////////////////////////////////////////

//// EC2 (WEBSERVER)
resource "aws_instance" "web_instance" {
  # Ubuntu Server 16.04 LTS (HVM), SSD Volume Type
  ami           = "ami-af79ebc0"
  instance_type = "t2.nano"
  key_name      = "deployer-key"
  iam_instance_profile = "${aws_iam_instance_profile.web_server_profile.name}"
  associate_public_ip_address = true

  vpc_security_group_ids = [
    "${aws_security_group.security_group_web.id}"
  ]
  subnet_id = "${aws_subnet.web_zone.id}"

  depends_on = ["aws_vpc.web_app_vpc", "aws_security_group.security_group_web", "aws_key_pair.deployer_key"]
}

//// DYNAMODB (NoSQL DATABASE)
resource "aws_dynamodb_table" "web_app_username_table" {
  name           = "Users"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"
  range_key      = "Username"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "Username"
    type = "S"
  }

  tags {
    Name = "WEB_APP_USERNAME_TABLE"
  }
}

resource "null_resource" "ansible_provisioner" {
  triggers {
    always = "${uuid()}"
  }

  provisioner "local-exec" {
    command = "sleep 20; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ../../ssh-keys/deployer-key -i '${aws_instance.web_instance.public_ip},' -e 'provider=aws' ../../ansible/web_server.deploy.yml"
  }

  depends_on = ["aws_instance.web_instance"]
}


//////////////////////////////////////////////////////////////////////
////
////   DEBUG CONFIGS
////
///////////////////////////////////////////////////////////////////////

output "web_server_ip" {
  value = "${aws_instance.web_instance.public_ip}"
}
