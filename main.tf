#
# IAM resources
#
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name               = "ecs${var.environment}ServiceRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_service_role" {
  role       = "${aws_iam_role.ecs_service_role.name}"
  policy_arn = "${var.ecs_service_role_policy_arn}"
}

#
# Security group resources
#
resource "aws_security_group" "main" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name        = "sg${var.name}LoadBalancer"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}

#
# ALB resources
#
resource "aws_alb" "main" {
  security_groups = ["${aws_security_group.main.id}"]
  subnets         = ["${var.public_subnet_ids}"]
  name            = "alb${var.environment}${var.name}"

  access_logs {
    bucket = "${var.access_log_bucket}"
    prefix = "${var.access_log_prefix}"
  }

  tags {
    Name        = "alb${var.environment}${var.name}"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_target_group" "main" {
  name = "tg${var.environment}${var.name}"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    timeout             = "3"
    path                = "${var.health_check_path}"
    unhealthy_threshold = "2"
  }

  port     = "${var.port}"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  tags {
    Name        = "tg${var.environment}${var.name}"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "443"
  protocol          = "HTTPS"

  certificate_arn = "${var.ssl_certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.main.id}"
    type             = "forward"
  }
}

#
# ECS resources
#
resource "aws_ecs_service" "main" {
  lifecycle {
    create_before_destroy = true
  }

  name                               = "${var.environment}${var.name}"
  cluster                            = "${var.cluster_name}"
  task_definition                    = "${var.task_definition_id}"
  desired_count                      = "${var.desired_count}"
  deployment_minimum_healthy_percent = "${var.deployment_min_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_max_percent}"
  iam_role                           = "${aws_iam_role.ecs_service_role.name}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.main.id}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }
}
