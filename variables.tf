variable "aws_region" {
  description = "La region de AWS donde se desplegaran los recursos."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "El tipo de instancia para los servidores web EC2."
  type        = string
  default     = "t2.micro"
}

variable "my_ip" {
  description = "La direccion IP para permitir el acceso SSH. Debe ser definida en terraform.tfvars."
  type        = string
}

variable "docker_images" {
  description = "Una lista de imagenes de Docker para desplegar en cada instancia."
  type        = list(string)
  default = [
    "errm/cheese:wensleydale",
    "errm/cheese:cheddar",
    "errm/cheese:stilton"
  ]
}

variable "ami_name_filter" {
  description = "Filtro name para buscar la AMI (data.aws_ami)."
  type        = string
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
}

variable "ami_owners" {
  description = "Owners para la busqueda de AMI (data.aws_ami)."
  type        = list(string)
  default     = ["amazon"]
}

variable "alb_name" {
  description = "Nombre del Application Load Balancer."
  type        = string
  default     = "cheese-alb"
}

variable "alb_tag_name" {
  description = "Valor de la etiqueta Name para el ALB."
  type        = string
  default     = "Cheese-ALB"
}

variable "tg_name" {
  description = "Nombre del Target Group."
  type        = string
  default     = "cheese-tg"
}

variable "alb_sg_name" {
  description = "Nombre del security group para el ALB."
  type        = string
  default     = "alb-security-group"
}

variable "web_sg_name" {
  description = "Nombre del security group para los servidores web."
  type        = string
  default     = "web-server-security-group"
}

variable "alb_sg_tag" {
  description = "Tag Name para el security group del ALB."
  type        = string
  default     = "ALB-SG"
}

variable "web_sg_tag" {
  description = "Tag Name para el security group de los servidores web."
  type        = string
  default     = "WebServer-SG"
}

variable "alb_ingress_cidr" {
  description = "CIDR que permitira acceso HTTP al ALB."
  type        = string
  default     = "0.0.0.0/0"
}

variable "public_subnet_count" {
  description = "Cuantas subnets publicas tomar para el ALB (slice hasta este numero)."
  type        = number
  default     = 3
}

variable "associate_public_ip" {
  description = "Determina si las instancias EC2 obtienen IP publica al lanzarse."
  type        = bool
  default     = true
}

variable "ssh_key_name" {
  description = "Nombre de la key pair EC2 para acceso SSH. Dejalo vacio si no deseas setearlo."
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "Usuario del sistema en la AMI (ej: ec2-user o ubuntu)."
  type        = string
  default     = "ec2-user"
}

variable "docker_publish_port" {
  description = "Mapeo de puertos host:container usado en docker run dentro de user-data."
  type        = string
  default     = "80:80"
}

variable "docker_run_extra_args" {
  description = "Argumentos extra para docker run (flags). Cadena vacia si no se usan."
  type        = string
  default     = ""
}

variable "health_check_port" {
  description = "Puerto usado por el target group y por las attachments."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Ruta usada por el health check del target group."
  type        = string
  default     = "/"
}

variable "health_check_protocol" {
  description = "Protocolo para health check y target group."
  type        = string
  default     = "HTTP"
}

variable "health_check_matcher" {
  description = "Matcher de respuesta del health check (ej: \"200\" o \"200-399\")."
  type        = string
  default     = "200"
}

variable "health_check_interval" {
  description = "Intervalo en segundos entre health checks."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout en segundos para cada health check."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Cantidad de checks exitosos consecutivos para marcar healthy."
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Cantidad de checks fallidos consecutivos para marcar unhealthy."
  type        = number
  default     = 2
}

variable "alb_idle_timeout" {
  description = "Idle timeout del ALB en segundos."
  type        = number
  default     = 60
}

variable "output_message_alb_instr" {
  description = "Mensaje instructivo previo al DNS del ALB en outputs."
  type        = string
  default     = "JCrovetto: Aca esta el nombre DNS publico del Application Load Balancer. Seleccionalo, copialo y pegalo en tu navegador web. Pulsa ENTER y empieza a jugar presionando F5 en tu navegador para ir cambiando de queso."
}

variable "output_message_ips_instr" {
  description = "Mensaje instructivo previo a la lista de IPs publicas en outputs."
  type        = string
  default     = "JCrovetto: Aca estan las direcciones IP publicas de las instancias EC2 para acceso SSH."
}

variable "output_message_final" {
  description = "Mensaje final que se muestra en outputs."
  type        = string
  default     = "JCrovetto: AWS a la concha de tu madre me tienes chato con tus mamadas."
}

variable "tags" {
  description = "Mapa de etiquetas aplicadas a recursos."
  type        = map(string)
  default     = {
    Environment = "dev"
    Owner       = "jcrovetto"
    Project     = "cheese"
  }
}
