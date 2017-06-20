# terraform-aws-ecs-web-service

A Terraform module to create an Amazon Web Services (AWS) EC2 Container Service (ECS) service associated with an Application Load Balancer (ALB).

## Usage

```hcl
resource "aws_ecs_task_definition" "app" {
  lifecycle {
    create_before_destroy = true
  }

  family                = "ProductionApp"
  container_definitions = "..."
}

module "app_web_service" {
  source = "github.com/azavea/terraform-aws-ecs-web-service?ref=0.1.0"

  name                = "App"
  vpc_id              = "vpc-..."
  public_subnet_ids   = ["subnet-...", "subnet-..."]
  access_log_bucket   = "logs-bucket"
  access_log_prefix   = "ALB"
  health_check_path   = "/health-check/"
  port                = "8080"
  ssl_certificate_arn = "arn..."

  cluster_name                   = "default"
  task_definition_id             = "${aws_ecs_task_definition.app.family}:${aws_ecs_task_definition.app.revision}"
  desired_count                  = "1"
  min_count                      = "1"
  max_count                      = "2"
  scale_up_cooldown_seconds      = "300"
  scale_down_cooldown_seconds    = "300"
  deployment_min_healthy_percent = "100"
  deployment_max_percent         = "200"
  container_name                 = "django"
  container_port                 = "8080"

  project     = "${var.project}"
  environment = "${var.environment}"
}

resource "aws_cloudwatch_metric_alarm" "app_service_high_cpu" {
  alarm_name          = "alarmAppCPUUtilizationHigh"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions {
    ClusterName = "default"
    ServiceName = "App"
  }

  alarm_actions = ["${module.app_web_service.appautoscaling_policy_scale_up_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "app_service_low_cpu" {
  alarm_name          = "alarmAppCPUUtilizationLow"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "15"

  dimensions {
    ClusterName = "default"
    ServiceName = "App"
  }

  alarm_actions = ["${module.app_web_service.appautoscaling_policy_scale_down_arn}"]
}
```

## Variables

- `name` - Name of the service in `CamelCase` without spaces
- `vpc_id` - ID of VPC housing the service
- `public_subnet_ids` - A list of public subnet IDs used to place load balancers
- `access_log_bucket` - Bucket name used to collect load balancer access logs
- `access_log_prefix` - Prefix within bucket to nest load balancer access logs
- `health_check_path` - Path to use for service health check (default: `/`)
- `port` - Port used for the load balancer target group
- `ssl_certificate_arn` - ARN of the certificate to associate with the HTTPS listener
- `cluster_name` - ECS cluster name to associate with the service
- `task_definition_id` - Concatenation of ECS task definition family and revision separated by a colon
- `ecs_service_role_name` - Name of IAM role for ECS tasks
- `ecs_autoscale_role_arn` - ARN of IAM role for ECS Application Autoscaling
- `desired_count` - Desired number of service instances (default: `1`)
- `min_count` - Minimum number of service instances (default: `1`)
- `max_count` - Maximum number of service instances (default: `1`)
- `deployment_min_healthy_percent` - Minimum healthy service instances as a percentage (default: `100`)
- `deployment_max_percent` - Maximum service instances as a percentage (default: `200`)
- `container_name` - Name of container in task definition to associate with load balancer
- `container_port` - Port exposed by container in task definition to associate with load balancer
- `scale_up_cooldown_seconds` - Amount of time, in seconds, after a scale up activity completes and before the next can start (default: `300`)
- `scale_down_cooldown_seconds` - Amount of time, in seconds, after a scale down activity completes before the next can start (default: `300`)
- `project` - Name of project for this service (default: `Unknown`)
- `environment` - Name of environment for this service (default: `Unknown`)

## Outputs

- `id` - The service ARN
- `name` - The service name
- `lb_zone_id` - Service load balancer hosted zone ID
- `lb_dns_name` - Service load balancer DNS name
- `lb_security_group_id` - Security group ID of load balancer security group
- `appautoscaling_policy_scale_up_arn` - ARN of Application AutoScaling policy to scale up
- `appautoscaling_policy_scale_down_arn` - ARN of Application AutoScaling policy to scale down
