provider "aws" {
  region = var.aws_region
}

# --- FUENTES DE DATOS DE LA CUENTA DE AWS ---

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = var.ami_owners
  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
}

# --- RECURSOS DE RED Y SEGURIDAD ---

resource "aws_security_group" "alb_sg" {
  name        = var.alb_sg_name
  description = "Permite el trafico HTTP desde internet"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Permitir HTTP desde el CIDR configurado"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.alb_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = var.alb_sg_tag })
}

resource "aws_security_group" "web_sg" {
  name        = var.web_sg_name
  description = "Permite SSH y HTTP desde el ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Permitir HTTP desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "Permitir SSH desde la IP configurada"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = var.web_sg_tag })
}

# --- RECURSOS DEL BALANCEADOR DE CARGA ---

resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = slice(data.aws_subnets.public.ids, 0, var.public_subnet_count)
  idle_timeout       = var.alb_idle_timeout

  tags = merge(var.tags, { Name = var.alb_tag_name })
}

resource "aws_lb_target_group" "main" {
  name     = var.tg_name
  port     = var.health_check_port
  protocol = var.health_check_protocol
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = var.health_check_path
    protocol            = var.health_check_protocol
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# --- SERVIDORES EC2 Y ASOCIACION ---

resource "aws_instance" "web_server" {
  count = length(var.docker_images)
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.public.ids, count.index)
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = var.associate_public_ip
  key_name                    = var.ssh_key_name != "" ? var.ssh_key_name : null

  user_data = templatefile("${path.module}/user_data.sh", {
    docker_image           = element(var.docker_images, count.index)
    docker_publish_port    = var.docker_publish_port
    docker_run_extra_args  = var.docker_run_extra_args
    ssh_user               = var.ssh_user
  })

  tags = merge(var.tags, {
    Name      = "WebServer-${count.index + 1}-${replace(element(var.docker_images, count.index), "/", "-")}"
    IsPrimary = count.index == 0 ? "true" : "false"
  })
}

resource "aws_lb_target_group_attachment" "web_server_attachment" {
  count = length(aws_instance.web_server)
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = var.health_check_port
}
