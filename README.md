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
  deployment_min_healthy_percent = "100"
  deployment_max_percent         = "200"

  container_name = "django"
  container_port = "8080"

  project     = "${var.project}"
  environment = "${var.environment}"
}
```

## Variables

- `ecs_service_role_policy_arn` - Policy ARN for ECS service role (default: `AmazonEC2ContainerServiceRole`)
- `vpc_id` - ID of VPC housing the service
- `name` - Name of the service
- `public_subnet_ids` - A list of public subnet IDs used to place load balancers
- `access_log_bucket` - Bucket name used to collect load balancer access logs
- `access_log_prefix` - Prefix within bucket to nest load balancer access logs
- `health_check_path` - Path to use for service health check (default: `/`)
- `port` - Port used for the load balancer target group
- `ssl_certificate_arn` - ARN of the certificate to associate with the HTTPS listener
- `cluster_name` - ECS cluster name to associate with the service
- `task_definition_id` - Concatenation of ECS task definition family and revision separated by a colon
- `desired_count` - Desired number of service instances (default: `1`)
- `deployment_min_healthy_percent` - Minimum healthy service instances as a percentage (default: `100`)
- `deployment_max_percent` - Maximum service instances as a percentage (default: `200`)
- `container_name` - Name of container in task definition to associate with load balancer
- `container_port` - Port exposed by container in task definition to associate with load balancer
- `project` - Name of project for this service (default: `Unknown`)
- `environment` - Name of environment for this service (default: `Unknown`)

## Outputs

- `id` - The service ARN
- `name` - The service name
- `lb_zone_id` - Service load balancer hosted zone ID
- `lb_dns_name` - Service load balancer DNS name
- `lb_security_group_id` - Security group ID of load balancer security group
