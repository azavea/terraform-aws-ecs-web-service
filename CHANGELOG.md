## 0.4.0

- Add support for providing additional ALB security groups with `security_group_ids` input.
- Remove `ecs_autoscale_role_arn` input.
- Fix `alb_target_group` errors for newer versions of AWS provider by adding `200` default matcher. 

## 0.3.0

- Fix `aws_appautoscaling_policy` deprecation warnings for newer versions of AWS provider.

## 0.2.0

- Remove IAM role creation, require role names and ARNs as inputs.

## 0.1.0

- Initial release.
