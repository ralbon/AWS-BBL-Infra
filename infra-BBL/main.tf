
## Instanciate REDIS

resource "aws_elasticache_replication_group" "redis-instance" {
  replication_group_id = "redis"
  replication_group_description = "Redis cluster for Hashicorp ElastiCache example"
  engine = "redis"
  number_cache_clusters = 2

  node_type = "cache.t2.micro"
  port = 6379
  parameter_group_name = "default.redis3.2"

  snapshot_retention_limit = 0


  security_group_ids = [
    "sg-ac2acbc4"]
}

## Instanciate POSTGRES

resource "aws_db_instance" "pg-vote" {
  identifier = "pg-vote"
  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "9.6.3"
  instance_class = "db.t2.micro"
  name = "postgres"
  username = "postgres"
  password = "postgres"

  vpc_security_group_ids = ["sg-ac2acbc4"]

  skip_final_snapshot = true
}

## Get AMI

data "aws_ami" "ec2-linux" {
  most_recent = true
  filter {
    name = "name"
    values = [
      "amzn-ami-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }
  filter {
    name = "owner-alias"
    values = [
      "amazon"]
  }
}

## Instanciate Result EC2

data "template_file" "user_data_result" {
  template = "${file("user_data_result.tpl")}"

  vars {
    PG_HOST="${aws_db_instance.pg-vote.address}"
  }
}

resource "aws_instance" "web-result" {
  ami = "${data.aws_ami.ec2-linux.id}"
  instance_type = "t2.micro"

  subnet_id = "subnet-f578e98e"
  vpc_security_group_ids = [
    "sg-844242ec",
    "sg-ac2acbc4"]

  key_name = "OCTO-BBL-AWS"
  user_data = "${data.template_file.user_data_result.rendered}"

  tags {
    Name = "catvsdog-result"
  }

}

## Instanciate Vote EC2

data "template_file" "user_data_vote" {
  template = "${file("user_data_vote.tpl")}"

  vars {
    REDIS_HOST="${aws_elasticache_replication_group.redis-instance.primary_endpoint_address}"
  }
}

resource "aws_instance" "web-vote" {
  ami = "${data.aws_ami.ec2-linux.id}"
  instance_type = "t2.micro"

  subnet_id = "subnet-f578e98e"
  vpc_security_group_ids = [
    "sg-09a08a61",
    "sg-ac2acbc4"]

  key_name = "OCTO-BBL-AWS"
  user_data = "${data.template_file.user_data_vote.rendered}"

  tags {
    Name = "catvsdog-vote"
  }
}

## Instanciate Result by dates API EC2

data "template_file" "user_data_result_by_date_api" {
  template = "${file("user_data_result_by_date_api.tpl")}"

  vars {
    API_RESULT_HOST="${aws_instance.web-result.private_ip}"
  }
}

resource "aws_instance" "web-result-by-date-api" {
  ami = "${data.aws_ami.ec2-linux.id}"
  instance_type = "t2.micro"

  subnet_id = "subnet-f578e98e"
  vpc_security_group_ids = ["sg-ac2acbc4"]

  key_name = "OCTO-BBL-AWS"
  user_data = "${data.template_file.user_data_result_by_date_api.rendered}"

  tags {
    Name = "catvsdog-result-by-date-api"
  }

}

## Instanciate Result by dates EC2

data "template_file" "user_data_result_by_date" {
  template = "${file("user_data_result_by_date.tpl")}"

  vars {
    API_HOST="${aws_instance.web-result-by-date-api.private_ip}"
  }
}

resource "aws_instance" "web-result-by-date" {
  ami = "${data.aws_ami.ec2-linux.id}"
  instance_type = "t2.micro"

  subnet_id = "subnet-f578e98e"
  vpc_security_group_ids = [
    "sg-26488b4d",
    "sg-ac2acbc4"]

  key_name = "OCTO-BBL-AWS"
  user_data = "${data.template_file.user_data_result_by_date.rendered}"

  tags {
    Name = "catvsdog-result-by-date"
  }

}

## Instanciate Lambda

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"


  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "ec2.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.iam_for_lambda.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_cloudwatch_event_rule" "trigger-rule" {
  name = "worker-trigger"
  description = "trigger db one minute"

  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "trigger-target" {
  rule = "${aws_cloudwatch_event_rule.trigger-rule.name}"
  target_id = "SendToVoteWorker"
  arn = "${aws_lambda_function.vote-worker.arn}"
}

resource "aws_lambda_permission" "worker-permission" {
  statement_id = "worker-permission"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.vote-worker.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.trigger-rule.arn}"
}

resource "aws_lambda_function" "vote-worker" {
  function_name = "voteWorker"
  s3_bucket = "archi-terraform-state"
  s3_key = "catvsdog-worker.zip"
  s3_object_version = "EddNNvIlRGC9igIiQZSKALV2bbWEt56U"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "app.voteWorker"
  runtime = "python2.7"
  timeout = 30

  vpc_config {
    security_group_ids = ["sg-ac2acbc4"]
    subnet_ids = ["subnet-9038e2dd"]
  }

  environment {
    variables = {
      REDIS_HOST = "${aws_elasticache_replication_group.redis-instance.primary_endpoint_address}"
      PG_HOST = "${aws_db_instance.pg-vote.address}"
    }
  }
}
