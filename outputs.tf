output "resumen_final" {
  value = format(
    "\n%s\n\"%s\"\n\n%s\n%s\n\n%s",

    var.output_message_alb_instr,
    aws_lb.main.dns_name,
    var.output_message_ips_instr,
    jsonencode(aws_instance.web_server[*].public_ip),
    var.output_message_final
  )
}
