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

  subnet_id = "subnet-f578e98e"
  vpc_security_group_ids = ["sg-844242ec", "sg-ac2acbc4"]


  tags {
    Name = "catvsdog-result"
  }
}

resource "aws_instance" "web-vote" {
  ami           = "${data.aws_ami.ec2-linux.id}"
  instance_type = "t2.micro"
  subnet_id = "subnet-f578e98e"
  vpc_security_group_ids = ["sg-09a08a61", "sg-ac2acbc4"]


  tags {
    Name = "catvsdog-vote"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "redis"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  security_group_ids = ["sg-ac2acbc4"]
}

resource "aws_db_instance" "pg-vote" {
  identifier           = "pg-vote"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "9.6.3"
  instance_class       = "db.t2.micro"
  name                 = "postgres"
  username             = "postgres"
  password             = "postgres"
  vpc_security_group_ids = ["sg-ac2acbc4"]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "vote-worker" {
  function_name    = "voteWorker"
  s3_bucket        = "archi-terraform-state"
  s3_key           = "catvsdog-worker.zip"
  s3_object_version = "EddNNvIlRGC9igIiQZSKALV2bbWEt56U"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "app.voteWorker"
  runtime          = "python2.7"

  environment {
    variables = {
#      REDIS_HOST = "${aws_elasticache_cluster.redis.connection}"
#      PG_HOST = "${aws_db_instance.pg-vote.address}"
    }
  }
}
