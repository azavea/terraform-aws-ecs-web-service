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
  iam_role                           = "${var.ecs_service_role_name}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.main.id}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }
}

#
# Application AutoScaling resources
#
resource "aws_appautoscaling_target" "main" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = "${var.ecs_autoscale_role_arn}"
  min_capacity       = "${var.min_count}"
  max_capacity       = "${var.max_count}"

  depends_on = [
    "aws_ecs_service.main",
  ]
}

resource "aws_appautoscaling_policy" "up" {
  name               = "appScalingPolicy${var.environment}${var.name}ScaleUp"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  adjustment_type         = "ChangeInCapacity"
  cooldown                = "${var.scale_up_cooldown_seconds}"
  metric_aggregation_type = "Average"

  step_adjustment {
    metric_interval_lower_bound = 0
    scaling_adjustment          = 1
  }

  depends_on = [
    "aws_appautoscaling_target.main",
  ]
}

resource "aws_appautoscaling_policy" "down" {
  name               = "appScalingPolicy${var.environment}${var.name}ScaleDown"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  adjustment_type         = "ChangeInCapacity"
  cooldown                = "${var.scale_down_cooldown_seconds}"
  metric_aggregation_type = "Average"

  step_adjustment {
    metric_interval_upper_bound = 0
    scaling_adjustment          = -1
  }

  depends_on = [
    "aws_appautoscaling_target.main",
  ]
}
