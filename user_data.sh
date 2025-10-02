#!/bin/bash
# user_data.sh - template consumido por templatefile desde Terraform
# Variables proporcionadas por Terraform:
#  - docker_image
#  - docker_publish_port (ej: "80:80")
#  - docker_run_extra_args (cadena con flags extra)
#  - ssh_user

# Actualiza paquetes e instala Docker
yum update -y
yum install -y docker
service docker start
usermod -a -G docker ${ssh_user}

# Ejecuta el contenedor Docker especificado por Terraform
# docker_publish_port debe ser del tipo "hostPort:containerPort"
# docker_run_extra_args permite pasar -e, -v, etc.
docker run -d --restart always -p ${docker_publish_port} ${docker_run_extra_args} ${docker_image} || true
