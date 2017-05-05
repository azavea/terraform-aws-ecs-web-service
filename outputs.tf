output "id" {
  value = "${aws_ecs_service.main.id}"
}

output "name" {
  value = "${aws_ecs_service.main.name}"
}

output "lb_zone_id" {
  value = "${aws_alb.main.zone_id}"
}

output "lb_dns_name" {
  value = "${aws_alb.main.dns_name}"
}

output "lb_security_group_id" {
  value = "${aws_security_group.main.id}"
}
