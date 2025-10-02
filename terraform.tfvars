# terraform.tfvars
# Archivo operativo. Reemplaza valores sensibles antes de usar en producción.

aws_region = "us-east-1"
instance_type = "t2.micro"

# IP para SSH: reemplaza por TU_IP_PUBLICA/32 en entornos reales
my_ip = "0.0.0.0/0"

docker_images = [
  "errm/cheese:wensleydale",
  "errm/cheese:cheddar",
  "errm/cheese:stilton",
]

ami_name_filter = "amzn2-ami-hvm-*-x86_64-gp2"
ami_owners = ["amazon"]

alb_name = "cheese-alb"
alb_tag_name = "Cheese-ALB"
tg_name = "cheese-tg"
alb_sg_name = "alb-security-group"
web_sg_name = "web-server-security-group"
alb_sg_tag = "ALB-SG"
web_sg_tag = "WebServer-SG"

alb_ingress_cidr = "0.0.0.0/0"

public_subnet_count = 3
associate_public_ip = true

ssh_key_name = "" # Ej: "mi-key-aws" o "" para no usar key pair
ssh_user = "ec2-user"

docker_publish_port = "80:80"
docker_run_extra_args = ""

health_check_port = 80
health_check_path = "/"
health_check_protocol = "HTTP"
health_check_matcher = "200"
health_check_interval = 30
health_check_timeout = 5
health_check_healthy_threshold = 2
health_check_unhealthy_threshold = 2

alb_idle_timeout = 60

output_message_alb_instr = "JCrovetto: Aca esta el nombre DNS publico del Application Load Balancer. Seleccionalo, copialo y pegalo en tu navegador web. Pulsa ENTER y empieza a jugar presionando F5 en tu navegador para ir cambiando de queso."
output_message_ips_instr = "JCrovetto: Aca estan las direcciones IP publicas de las instancias EC2 para acceso SSH."
output_message_final = "JCrovetto: AWS a la concha de tu madre me tienes chato con tus mamadas."

tags = {
  Environment = "dev"
  Owner       = "jcrovetto"
  Project     = "cheese"
}
