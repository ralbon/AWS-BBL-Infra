data "aws_ami" "ec2-linux" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn-ami-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_instance" "web-result" {
  ami           = "${data.aws_ami.ec2-linux.id}"
  instance_type = "t2.micro"

  tags {
    Name = "catvsdog-result"
  }
}

resource "aws_instance" "web-vote" {
  ami           = "${data.aws_ami.ec2-linux.id}"
  instance_type = "t2.micro"

  tags {
    Name = "catvsdog-vote"
  }
}




