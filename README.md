# Evaluación Parcial 1 | Infraestructura como código I (001V).
Juan Ignacio Crovetto Navarro.


## Propósito del proyecto .

El proyecto consiste en una arquitectura en la nube de AWS con tres servidores web, cada uno ejecutando un contenedor Docker que muestra un tipo de queso diferente. Un balanceador de carga se encargará de distribuir el tráfico entre estos servidores para asegurar la disponibilidad y el rendimiento.

En este proyecto se deben aplicar los conocimientos adquiridos en el curso de Infraestructura como Código para: desplegar una arquitectura web simple, escalable y segura en Amazon Web Services utilizando Terraform.

Se debe demostrar el dominio en el uso de variables, archivos de variables, expresiones condicionales y funciones nativas de Terraform.

Se debe realizar la actividad y gestionar todo el código en un repositorio propio de Git para la entrega y posterior evaluación del trabajo.

No se requiere informe, solo adjuntar en AVA el enlace correspondiente donde están albergados los archivos.


## Estructura de los archivos:

main.tf

En main.tf declaro el proveedor AWS, recojo datos de la cuenta y de la red existentes, y defino todos los recursos activos que necesito desplegar: grupos de seguridad, Application Load Balancer (ALB), target group, listeners, instancias EC2 y las asociaciones de targets; este archivo contiene la lógica de infraestructura y las referencias entre recursos que Terraform aplica como un solo plan.


variables.tf

En variables.tf defino las entradas parametrizables que uso en el resto de la configuración —por ejemplo la región, el tipo de instancia, la IP permitida para SSH y la lista de imágenes Docker—; estas variables me permiten reutilizar y adaptar el mismo código sin editar recursos directamente, y definen tipos y valores por defecto cuando corresponde.


terraform.tfvars

En terraform.tfvars coloco los valores concretos para las variables obligatorias o que quiero sobrescribir en este entorno específico; Terraform los carga automáticamente al ejecutar plan/apply y así doy valores operativos (en tu caso la variable my_ip con un valor que permite acceso SSH desde cualquier IP).


terraform.tfvars.example

En terraform.tfvars.example dejo ejemplos y opciones documentadas para que quien instale el código sepa cómo rellenar terraform.tfvars de forma segura o temporal; lo uso como plantilla y guía para evitar errores al proporcionar valores requeridos.


user_data.sh

En user_data.sh incluyo el script que se ejecutará en el arranque de cada instancia EC2; en él actualizo paquetes, instalo y arranco Docker, añado el usuario ec2-user al grupo docker y lanzo el contenedor Docker que le paso desde Terraform mediante userdata, garantizando que la aplicación contenido en la imagen quede en ejecución automáticamente tras el provisioning.


outputs.tf

En outputs.tf declaro las salidas que quiero mostrar al terminar el despliegue —en tu caso un único resumen_final formateado con el DNS público del ALB y las IPs públicas de las instancias—; las salidas me permiten comunicar URLs, IPs, ARNs u otros valores útiles que serán visibles tras un terraform apply y que pueden integrarse en otros módulos o scripts.


## Ejecución:

1.- Requisitos previos:

- Ubuntu 24.04.3 LTS con acceso a la terminal.

- Tener instalado Terraform y AWS CLI v2.

- Disponer de credenciales AWS (Access Key ID y Secret Access Key) con permisos suficientes para crear EC2, ELB/ALB, Security Groups y leer VPC/AMI.

- Visual Studio Code (para crear y trabajar en los archivos).

- Descarga los archivos de este repositorio y recuerda la carpeta en donde estan (dejaste) los archivos de este proyecto.

2.- Configuración AWS CLI:

- Ejecuta en la terminal:

aws configure

E ingresa la información que te vaya pidiendo.

- Ya con la información ingresada, verifica la identidad dentro de AWS (esto te permitirá también saber si estas conectado correctamente).

Ejecuta en la terminal:

aws sts get-caller-identity


3.- Flujo de despliegue:

1 - Dentro de la terminal, dirígete a la carpeta donde tengas los archivos del proyecto, y estando dentro de ella (y habiendo confirmado que todos los archivos están dentro), inicializa el directorio de Terraform (descarga providers y prepara el workspace) con el siguiente comando en la terminal:

terraform init

2 - Valida la consistencia de los archivos Terraform con:

terraform validate

3 - Crea un plan con:

terraform plan

4 - Aplica el plan guardado exactamente como fue diseñado con:

terraform apply

(pedirá confirmación interactiva)

5 - Opcional: Obtén salidas útiles tras apply (DNS del ALB y IPs públicas):

terraform output resumen_final

terraform output -json


4.- Verificación post-despliegue y pruebas funcionales.

- Verifica que el ALB responde desde el navegador o curl usando el DNS mostrado.

Para esta evaluación en particular, en el navegador, después de entrar en la dirección entregada por la terminal, ve refrescando la pagina (actualizando) con F5 por ejemplo en Mozilla Firefox y veras como iras saltando de queso en queso. Son 3 quesos distintos. Fíjate en el nombre de cada queso, ese es su identificador. Si saltas por los 3 nombres distintos, entonces funciona todo correctamente.

- Si configuraste ssh_key_name y my_ip correctamente, te puedes conectar a una instancia:

ssh -i /ruta/a/mi-key.pem ${ssh_user}@<IP_PUBLICA_DE_INSTANCIA>
#usuario por defecto: ec2-user salvo que lo cambies en terraform.tfvars (ssh_user)

- Comprueba contenedores y logs dentro de una instancia (SSH):

sudo docker ps -a
sudo docker logs <CONTAINER_ID>

- Verifica health checks en la consola AWS o con describe-target-health si tengo AWS CLI suficiente:

#Reemplazar target group ARN por el que muestra terraform show o la consola
aws elbv2 describe-target-health --target-group-arn <TG_ARN>


5.- Destrucción y limpieza.

- Cuando termines las pruebas, destruye la infraestructura con Terraform:

terraform destroy
#confirma la operación cuando te lo pida

(opcional)
Para borrar sin confirmaciones:

terraform destroy -auto-approve

Y con esto eliminaste todos los recursos creados por el state de Terraform para evitar facturación continua.


## Resolución rápida de problemas comunes:

- Error: "variable ... not defined" → Revisa variables.tf y terraform.tfvars; agrega la variable faltante o define su valor en terraform.tfvars..

- Error de permisos AWS (AccessDenied) → Verifica aws sts get-caller-identity y revisa las políticas del IAM user/role usado.

- Error AMI no encontrada → Revisa ami_name_filter y ami_owners en terraform.tfvars; adapta el filtro a la región.

- Error al hacer templatefile → Verifica rutas y sintaxis en user_data.sh; corre terraform validate para detectar plantillas inválidas.

- Problemas con Docker en EC2 → SSH a la instancia y ejecuta sudo docker ps -a y sudo journalctl -u docker -n 200.


## Expresiones Condicionales y Funciones:
(Algunas. Para mas en detalle y revisión extensa y completa, favor revisar archivo por archivo con un editor de codigo).


### Archivo: main.tf

Tipo: Expresión condicional (ternary)  
Detalle:  
key_name = var.ssh_key_name != "" ? var.ssh_key_name : null

-   Evaluación booleana: compruebo si la variable **ssh_key_name** es distinta de cadena vacía.
-   Resultado verdadero: asigno el valor de **var.ssh_key_name** al atributo **key_name** del recurso aws_instance.
-   Resultado falso: asigno **null**, lo que evita especificar key_name y deja la instancia sin key pair.
-   Efecto en la infraestructura: permite al usuario decidir desde terraform.tfvars si las instancias deben crearse con una key pair o no, sin editar recursos.

----------

Tipo: Expresión condicional (ternary)  
Detalle:  
IsPrimary = count.index == 0 ? "true" : "false"

-   Condición: verifico si **count.index** (índice de la instancia creada) es igual a 0.
-   Resultado verdadero: la etiqueta **IsPrimary** recibe la cadena `"true"`.
-   Resultado falso: la etiqueta **IsPrimary** recibe la cadena `"false"`.
-   Efecto en la infraestructura: marca la primera instancia del conjunto creado (índice 0) como primaria mediante la etiqueta IsPrimary; el resto queda marcado como no primaria.

----------

Tipo: Función nativa — element (colecciones)  
Detalle:  
element(var.docker_images, count.index)

-   Qué hace: toma la lista **var.docker_images** y devuelve el elemento cuyo índice es **count.index**.
-   Uso en el código: se pasa al templatefile como `docker_image = element(var.docker_images, count.index)` y se usa para construir el tag Name con replace alrededor.
-   Efecto en la infraestructura: asigna a cada instancia una imagen Docker específica según su índice, sincronizando imágenes con instancias creadas por count.

----------

Tipo: Función nativa — replace (string)  
Detalle:  
replace(element(var.docker_images, count.index), "/", "-")

-   Qué hace: toma la cadena devuelta por element(...) y reemplaza todas las barras `/` por guiones `-`.
-   Uso en el código: se inserta en la etiqueta Name de la instancia para sanitizar la cadena de la imagen.
-   Efecto en la infraestructura: genera nombres de recurso legibles y sin caracteres problemáticos en las etiquetas, p. ej. convierte `errm/cheese:cheddar` en `errm-cheese:cheddar`.

----------

Tipo: Función nativa — length (colecciones)  
Detalle:  
count = length(var.docker_images)  
count = length(aws_instance.web_server)

-   Qué hace: calcula el número de elementos en una lista.
-   Uso en el código: en aws_instance uso `count = length(var.docker_images)` para crear tantas instancias como imágenes; en aws_lb_target_group_attachment uso `count = length(aws_instance.web_server)` para crear attachments equivalentes.
-   Efecto en la infraestructura: asegura que el número de instancias y attachments se mantenga sincronizado con la lista de imágenes.

----------

Tipo: Función nativa — element (subnets)  
Detalle:  
subnet_id = element(data.aws_subnets.public.ids, count.index)

-   Qué hace: selecciona la subnet pública cuyo índice coincide con el índice de la instancia.
-   Efecto en la infraestructura: distribuye las instancias entre subnets públicas disponibles en orden, evitando asignarlas todas a la misma subnet.

----------

Tipo: Función nativa — slice (colecciones)  
Detalle:  
subnets = slice(data.aws_subnets.public.ids, 0, var.public_subnet_count)

-   Qué hace: toma un subconjunto de la lista de subnets públicas desde índice 0 hasta `var.public_subnet_count` (límite superior).
-   Efecto en la infraestructura: controla cuántas subnets públicas se pasan al ALB mediante la variable **public_subnet_count**, permitiendo personalizar la distribución del ALB sin cambiar código.

----------

Tipo: Función nativa — templatefile (plantilla)  
Detalle:  
user_data = templatefile("${path.module}/user_data.sh", { docker_image = element(var.docker_images, count.index), docker_publish_port = var.docker_publish_port, docker_run_extra_args = var.docker_run_extra_args, ssh_user = var.ssh_user })

-   Qué hace: procesa el archivo `user_data.sh` como plantilla, reemplaza los placeholders con los valores pasados desde Terraform y devuelve el contenido final para user_data.
-   Efecto en la infraestructura: inyecta en cada instancia la orden para arrancar Docker con la imagen y argumentos configurados en terraform.tfvars.

----------

Tipo: Función nativa — merge (mapas)  
Detalle:  
tags = merge(var.tags, { Name = var.alb_sg_tag }) y variantes (ej. en instancias merge(var.tags, { Name = ..., IsPrimary = ... }))

-   Qué hace: combina el mapa global **var.tags** con un mapa adicional específico del recurso, sobrescribiendo claves si existen.
-   Efecto en la infraestructura: aplica etiquetas globales coherentes mientras añade o sobrescribe etiquetas por recurso (Name, IsPrimary), facilitando inventariado y facturación.

----------

Tipo: Operador splat y acceso por índice a recursos  
Detalle:  
aws_instance.web_server[count.index] y aws_instance.web_server[*].public_ip

-   Qué hace: `aws_instance.web_server[count.index]` accede a la instancia específica por índice; `aws_instance.web_server[*].public_ip` usa splat para obtener la lista de public_ip de todas las instancias.
-   Efecto en la infraestructura: permite crear attachments por índice y recoger todas las IPs para outputs.

----------

Tipo: Variable predefinida — path.module  
Detalle:  
"${path.module}/user_data.sh" dentro de templatefile

-   Qué hace: devuelve la ruta del módulo actual para construir la ruta absoluta al archivo user_data.sh.
-   Efecto en la infraestructura: asegura que Terraform encuentre la plantilla user_data.sh de forma relativa al módulo, independientemente desde dónde se ejecute.

----------

### Archivo: variables.tf

Tipo: Declaración de variables (no expresiones)  
Detalle:  
Bloques `variable "nombre" { description = "..."; type = ...; default = ... }` para variables como `docker_images`, `ssh_key_name`, `health_check_*`, `tags`, etc.

-   Qué hace: define el esquema y valores por defecto de los parámetros que controlan recursos en main.tf.
-   Efecto en la infraestructura: centraliza la parametrización, habilita que terraform.tfvars controle comportamiento y permite validación de tipos implícita por Terraform.

----------

### Archivo: outputs.tf

Tipo: Función nativa — format (formateo de cadenas)  
Detalle:  
value = format("\n%s\n"%s"\n\n%s\n%s\n\n%s", var.output_message_alb_instr, aws_lb.main.dns_name, var.output_message_ips_instr, jsonencode(aws_instance.web_server[*].public_ip), var.output_message_final)

-   Qué hace: combina múltiples valores y cadenas formateadas en una única cadena de salida con placeholders `%s`.
-   Efecto en la infraestructura: genera un output consolidado y legible que incluye instrucciones personalizables y los datos operativos (DNS e IPs).

----------

Tipo: Función nativa — jsonencode (serialización)  
Detalle:  
jsonencode(aws_instance.web_server[*].public_ip)

-   Qué hace: convierte la lista de IPs públicas devuelta por el splat `aws_instance.web_server[*].public_ip` en una cadena JSON.
-   Efecto en la infraestructura: permite mostrar la colección de IPs en una sola línea o bloque en el output, facilitando lectura y procesamiento por scripts.

----------

### Archivo: user_data.sh

Tipo: Plantilla (variables shell) consumida por templatefile  
Detalle:  
docker run -d --restart always -p ${docker_publish_port} ${docker_run_extra_args} ${docker_image} || true

-   Qué hace: usa las variables inyectadas por templatefile (`${docker_publish_port}`, `${docker_run_extra_args}`, `${docker_image}`) para ejecutar el contenedor Docker deseado.
-   Efecto en la infraestructura: en cada instancia EC2, el user_data instala Docker, arranca el demonio y ejecuta el contenedor configurado; el `|| true` evita fallo del user_data si docker run falla al final del script.

----------

Tipo: Scripts bash y sustitución de variables (no funciones Terraform)  
Detalle:  
usermod -a -G docker ${ssh_user}

-   Qué hace: añade el usuario referido por `${ssh_user}` al grupo docker dentro de la instancia.
-   Efecto en la infraestructura: permite que el usuario definido pueda ejecutar comandos docker sin sudo.

----------

### Archivo: terraform.tfvars

Tipo: Valores asignados (no expresiones ni funciones)  
Detalle:  
Asignaciones concretas como `aws_region = "us-east-1"`, `my_ip = "0.0.0.0/0"`, `docker_images = [...]`, `health_check_port = 80`, `tags = {...}`, etc.

-   Qué hace: provee los valores reales que consumen las variables declaradas en variables.tf.
-   Efecto en la infraestructura: al editar terraform.tfvars el usuario personaliza región, imágenes, puertos, conteos y comportamiento sin tocar archivos .tf.

----------

### Archivo: terraform.tfvars.example

Tipo: Valores de ejemplo y comentarios (no expresiones ni funciones)  
Detalle:  
Entradas documentadas con ejemplos y explicaciones para cada variable presente en variables.tf, incluyendo `docker_images`, `ssh_key_name`, `my_ip`, `docker_publish_port`, `health_check_*`, `alb_*`, `tags`, etc.

-   Qué hace: guía al usuario sobre formato y valores recomendados para terraform.tfvars.
-   Efecto en la infraestructura: facilita que un usuario configure correctamente terraform.tfvars para desplegar la infraestructura según sus necesidades.

----------

### Evaluación Parcial 1 | Infraestructura como código I (001V).
Juan Ignacio Crovetto Navarro.
