/*
É uma boa prática de colocar todos os provedores dentro do bloco terraform, com sua respectiva fonte e versão
It's a best practice to specify all providers inside the terraform block, each with its respective source and version.
*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "devops_vexpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "DiogoTGC"
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"
  }
}

resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

  /*
  O recurso aws_route_table_association não aceita o argumento "tag" conforme mostrado na documentação.
  The resource aws_route_table_association doesn't accept the argument "tag" as it is show in the documentation.

  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"
  }
  */
}

resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  # Regras de entrada
  ingress {
    description      = "Allow SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"
  }
}

/*
Criado um domínio com route 53
Created a domain with route 53
*/
resource "aws_route53_zone" "main_zone" {
  name = "dominio.com"
}


data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]
  /*
  Desse jeito fica explícito que a instância EC2 depende do gateway
  Mesmo já estando assegurado no subnet através da assosciação da tabela de rota

  This way it's clear that the EC2 instance depends on gateway
  Even if it is assured in subnet through the route table association
  */
  depends_on = [ aws_internet_gateway.main_igw ]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  /*
  Instalando e iniciando o nginx automaticamente
  Installing and starting the nginx automatically 
  */
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install nginx -y
              systemctl enable nginx --now
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}

/*
Criado um sub-domínio com o record do route 53, para que seja enviado para a instância EC2
Created a subdomain with route 53, so it can send to EC2 instance
*/
resource "aws_route53_record" "ec2_subdomain" {
  zone_id = aws_route53_zone.main_zone.zone_id
  name    = "ec2.dominio.com"  # Subdomínio
  type    = "A"
  ttl     = 300

  records = [aws_instance.debian_ec2.public_ip]
}

/*
Criado um aws_acm_certificate para trazer melhor segurança ao domínio que está a instância EC2 com o Route 53
Created an aws_acm_certificate to bring more security to domain there is the EC2 instance with Route 53
*/
resource "aws_acm_certificate" "example_cert" {
  domain_name       = aws_route53_record.ec2_subdomain.name // "ec2.dominio.com"
  validation_method = "DNS"

  /*
  Desse jeito sempre terá criado um certificado antes de destruir o antigo
  Like this it will always create a nem certificate before destroying the old one
  */
  lifecycle {
    create_before_destroy = true
  }
}

/*
Criado um sub-domínio com o record do route 53, apenas para validar o aws_acm_certificate
Created a subdomain with route 53, only to validate the aws_acm_certificate
*/
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for ocurrency in aws_acm_certificate.example_cert.domain_validation_options : ocurrency.domain_name => {
      name    = ocurrency.resource_record_name
      type    = ocurrency.resource_record_type
      record  = ocurrency.resource_record_value
    }
  }

  zone_id  = aws_route53_zone.main_zone.zone_id
  name     = each.value.name
  type     = each.value.type
  records  = [ each.value.record ]
  ttl      = 60
}

/*
Este recurso implementa a validação do certificado
This resource implements the validation of a certificate 
*/
resource "aws_acm_certificate_validation" "example_cert" {
  certificate_arn         = aws_acm_certificate.example_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  depends_on              = [aws_route53_record.cert_validation]
}

output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}
