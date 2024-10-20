# Explicação main.tf

Explicação do código original do desafio, explicação de mudanças estão como comentários no próprio código.

## Definição do provedor e variáveis

### **1\. Bloco `provider`**
```
provider "aws" {  
  region = "us-east-1"  
}
```
Este bloco define o **provedor** que o Terraform usará para interagir com a infraestrutura. O Terraform usa **provedores** para saber como se comunicar com os serviços da nuvem, como a AWS, GCP, Azure, etc.

* **"aws"**: Este é o nome do provedor (AWS neste caso).  
* **`region = "us-east-1"`**: Define a região da AWS onde os recursos serão criados. A região "us-east-1" se refere à região da Virgínia do Norte.

### **2\. e 3\. Bloco `variable "projeto"` `variable "candidato"`**
```
variable "projeto" {  
  description = "Nome do projeto"  
  type        = string  
  default     = "VExpenses"
}

variable "candidato" {  
  description = "Nome do candidato"  
  type        = string  
  default     = "SeuNome"  
}
```
Este bloco define duas **variáveis** chamadas `projeto` e `candidato`. Variáveis no Terraform são usadas para parametrizar a infraestrutura, permitindo reutilização.

* **`description`**: Explica o propósito da variável, que aqui é "Nome do projeto" ou "Nome do candidato".  
* **`type = string`**: Define o tipo de dado da variável como `string` (cadeia de caracteres).  
* **`default = "VExpenses"` e `default = "SeuNome"`**: Especifica um valor padrão para a variável, no caso "VExpenses" e "SeuNome". Se o valor não for passado explicitamente, o Terraform usará este valor.

## Definição de um provedor e a criação da chave SSH

### **1\. Bloco `resource "tls_private_key" "ec2_key"`**
```
resource "tls_private_key" "ec2_key" { 
  algorithm = "RSA"
  rsa_bits  = 2048
}
```
Este bloco define um **recurso** chamado `tls_private_key`, que é um **provedor** específico para gerar chaves criptográficas TLS (Transport Layer Security). No caso, uma chave privada para autenticação SSH será criada.

* **`algorithm = "RSA"`**: Define que o algoritmo usado para gerar a chave será o **RSA** (Rivest–Shamir–Adleman), um algoritmo criptográfico amplamente usado para criar chaves públicas e privadas.  
* **`rsa_bits = 2048`**: Especifica o tamanho da chave RSA em bits. Neste caso, será gerada uma chave de 2048 bits.

### **2\. Bloco `resource "aws_key_pair" "ec2_key_pair"`**
```
resource "aws_key_pair" "ec2_key_pair" {  
  key_name   = "${var.projeto}-${var.candidato}-key"  
  public_key = tls_private_key.ec2_key.public_key_openssh  
}
```
Este bloco define um recurso da AWS chamado `aws_key_pair`, que cria um **par de chaves** SSH na AWS.

* **`key_name = "${var.projeto}-${var.candidato}-key"`**: Define o nome do par de chaves. Aqui, o nome é composto pela concatenação dos valores das variáveis `projeto` e `candidato`, seguidos de `-key`.
* **`public_key = tls_private_key.ec2_key.public_key_openssh`**: Atribui a chave pública gerada pelo recurso `tls_private_key` ao par de chaves AWS. O atributo `public_key_openssh` fornece a chave pública no formato compatível com OpenSSH.

## Criação de uma VPC, subnet e gateway

### **1\. Bloco `resource "aws_vpc" "main_vpc"`**
```
resource "aws_vpc" "main_vpc" {  
  cidr_block           = "10.0.0.0/16"  
  enable_dns_support   = true  
  enable_dns_hostnames = true

  tags = {  
    Name = "${var.projeto}-${var.candidato}-vpc"  
  }  
}
```
Este bloco cria uma **VPC** (Virtual Private Cloud) na AWS, que é uma rede virtual isolada onde você pode executar seus recursos da nuvem.

* **`cidr_block = "10.0.0.0/16"`**: Define o bloco CIDR (Classless Inter-Domain Routing) da VPC, que é o intervalo de endereços IP para essa rede. 
* **`enable_dns_support = true`**: Ativa o suporte a DNS dentro da VPC, permitindo que os recursos dentro dela resolvam nomes de domínio.  
* **`enable_dns_hostnames = true`**: Habilita a atribuição de nomes DNS públicos para os recursos da VPC, para que eles possam ser acessados por um nome, além do endereço IP.  
* **`tags {Name}`**: Adiciona tags à VPC. O nome da tag será uma combinação das variáveis `projeto` e `candidato`.  Isso facilita a identificação e organização dos recursos na AWS.

### **2\. Bloco `resource "aws_subnet" "main_subnet"`**
```
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}
```
Este bloco cria uma **sub-rede** dentro da VPC, que é uma subdivisão do espaço de endereços IP da VPC.

* **`vpc_id = aws_vpc.main_vpc.id`**: Associa a sub-rede à VPC criada anteriormente, referenciada aqui pelo identificador da VPC.  
* **`cidr_block = "10.0.1.0/24"`**: Define o bloco CIDR da sub-rede, o intervalo `10.0.1.0/24`, que serão usados para alocar IPs para recursos.  
* **`availability_zone = "us-east-1a"`**: Especifica que a sub-rede será criada na zona de disponibilidade "us-east-1a". Zonas de disponibilidade são regiões físicas independentes dentro de uma região da AWS.  
* **`tags {Name}`**: Adiciona tags à sub-rede, nomeando-a também com base nas variáveis `projeto` e `candidato`.

### **3\. Bloco `resource "aws_internet_gateway" "main_igw"`**
```
resource "aws_internet_gateway" "main_igw" {  
  vpc_id = aws_vpc.main_vpc.id

  tags = {  
    Name = "${var.projeto}-${var.candidato}-igw"  
  }  
}
```
Este bloco cria um **Internet Gateway** (IGW), que é um ponto de entrada e saída da internet para a VPC. Ele permite que instâncias dentro da VPC se comuniquem com a internet.

* **`vpc_id = aws_vpc.main_vpc.id`**: Associa o Internet Gateway à VPC criada anteriormente.  
* **`tags {Name}`**: Adiciona tags ao Internet Gateway, nomeando-o com base nas variáveis `projeto` e `candidato`.

## Criação da tabela de rotas e associação a subnet

### **1\. Bloco `resource "aws_route_table" "main_route_table"`**
```
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
```
Este bloco cria uma **tabela de rotas** para a VPC, que define como o tráfego será roteado entre a VPC e a internet.

* **`vpc_id = aws_vpc.main_vpc.id`**: Associa a tabela de rotas à VPC criada anteriormente, referenciada pelo ID da VPC.  
* **`route`**: Dentro do bloco `route`, é configurada uma rota específica.  
  * **`cidr_block = "0.0.0.0/0"`**: Define o bloco CIDR para a rota, onde `0.0.0.0/0` representa "qualquer destino na internet".  
  * **`gateway_id = aws_internet_gateway.main_igw.id`**: Define que o tráfego com destino à internet (conforme definido pelo CIDR `0.0.0.0/0`) será roteado através do **Internet Gateway**.  
* **`tags {Name}`**: Adiciona uma tag à tabela de rotas, nomeando-a com base nas variáveis `projeto` e `candidato`.

### **2\. Bloco `resource "aws_route_table_association" "main_association"`**
```
resource "aws_route_table_association" "main_association" {  
  subnet_id      = aws_subnet.main_subnet.id  
  route_table_id = aws_route_table.main_route_table.id
}
```
Este bloco associa a **tabela de rotas** criada anteriormente à **sub-rede** dentro da VPC. A associação entre sub-rede e tabela de rotas é necessária para que o tráfego da sub-rede siga as rotas definidas.

* **`subnet_id = aws_subnet.main_subnet.id`**: Identifica a sub-rede que será associada à tabela de rotas.  
* **`route_table_id = aws_route_table.main_route_table.id`**: Identifica a tabela de rotas que será associada à sub-rede.

## Criação do security group

### **Bloco `resource "aws_security_group" "main_sg"`**
```
resource "aws_security_group" "main_sg" {  
  name        = "${var.projeto}-${var.candidato}-sg"  
  description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"  
  vpc_id      = aws_vpc.main_vpc.id

  ingress {...}
  egress {...}

  tags = {  
    Name = "${var.projeto}-${var.candidato}-sg"  
  }
```
Este bloco cria um **Security Group** associado à VPC especificada. O **Security Group** controla o tráfego que é permitido entrar e sair de recursos.

* **`name = "${var.projeto}-${var.candidato}-sg"`**: Define o nome do Security Group, que é composto pelas variáveis `projeto` e `candidato`.  
* **`description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"`**: Uma descrição breve que explica que as possibilidades do grupo de segurança.  
* **`vpc_id = aws_vpc.main_vpc.id`**: Associa o Security Group à VPC criada anteriormente, usando o ID da VPC.
* **`tags {Name}`**: Adiciona uma tag ao Security Group com o nome baseado nas variáveis `projeto` e `candidato`.

### **1\. Bloco `ingress` (Regras de Entrada)**
 ```
  ingress {  
    description      = "Allow SSH from anywhere"  
    from_port        = 22  
    to_port          = 22  
    protocol         = "tcp"  
    cidr_blocks      = ["0.0.0.0/0"]  
    ipv6_cidr_blocks = ["::/0"]  
  }
  ```
Este bloco define as **regras de entrada** para o Security Group, controlando quais conexões de rede externas são permitidas entrar nas instâncias associadas a esse grupo.

* **`description = "Allow SSH from anywhere"`**: Descrição que indica que esta regra permite conexões SSH.  
* **`from_port = 22` e `to_port = 22`**: Especifica que o tráfego permitido será apenas na **porta 22**, que é a porta padrão para conexões SSH.  
* **`protocol = "tcp"`**: Define que o protocolo permitido é o **TCP**, que é usado para SSH.  
* **`cidr_blocks = ["0.0.0.0/0"]`**: Permite o tráfego de qualquer endereço IPv4, já que o bloco CIDR "0.0.0.0/0" significa "qualquer origem".  
* **`ipv6_cidr_blocks = ["::/0"]`**: Permite o tráfego de qualquer endereço IPv6.

Esta regra permite que qualquer pessoa na internet possa se conectar às instâncias da VPC via SSH (porta 22).

### **2\. Bloco `egress` (Regras de Saída)**
```
  egress {  
    description      = "Allow all outbound traffic"  
    from_port        = 0  
    to_port          = 0  
    protocol         = "-1"  
    cidr_blocks      = ["0.0.0.0/0"]  
    ipv6_cidr_blocks = ["::/0"]  
  }
```
Este bloco define as **regras de saída**, ou seja, quais tipos de tráfego podem sair das instâncias associadas ao grupo de segurança.

* **`description = "Allow all outbound traffic"`**: Descrição da regra que permite todo o tráfego de saída.  
* **`from_port = 0` e `to_port = 0`**: Define que o tráfego de todas as portas é permitido.  
* **`protocol = "-1"`**: O valor `-1` significa "todos os protocolos". Ou seja, não há restrição de protocolo para o tráfego de saída.  
* **`cidr_blocks = ["0.0.0.0/0"]`** Permite que o tráfego de saída vá para qualquer endereço IPv4.  
* **`ipv6_cidr_blocks = ["::/0"]`** Permite que o tráfego de saída vá para qualquer endereço IPv6.

Esta regra permite que as instâncias na VPC possam se comunicar com qualquer endereço IP na internet, independentemente do protocolo ou porta.

## Busca de uma AMI (Amazon Machine Images)

### **Bloco `data "aws_ami" "debian12"`**
```
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
```
Este bloco de código consulta a AWS para recuperar uma AMI específica com base em certos filtros. O data source `aws_ami` é útil quando precisa referenciar uma AMI específica sem fornecer um ID fixo.

### **Campos explicados:**

* **`most_recent = true`**: Este parâmetro diz ao Terraform para buscar a AMI mais recente que corresponda aos filtros especificados\.
* **`owners = ["679593333241"]`**: Este campo especifica o ID do proprietário das AMIs que devem ser consideradas.

### **1\. Bloco `filter` (Filtro de nome)**
```
  filter {  
    name   = "name"  
    values = ["debian-12-amd64-*"]  
  }
```
Este filtro define que a consulta irá buscar por AMIs que corresponda ao nome `"debian-12-amd64-*"`, o objetivo é encontrar uma imagem do sistema operacional **Debian 12** para a arquitetura **AMD64** (64-bit).

### **2\. Bloco `filter` (Filtro de tipo de virtualização)**
```
  filter { 
    name   = "virtualization-type"  
    values = ["hvm"]  
  }
```
Este filtro define que a AMI deve ser compatível com a **virtualização do tipo HVM (Hardware Virtual Machine)**. O tipo HVM utiliza a aceleração de hardware disponível em servidores mais recentes para melhorar o desempenho.

## Criação do EC2

### **Bloco `resource "aws_instance" "debian_ec2"`**
```
resource "aws_instance" "debian_ec2" {  
  ami             = data.aws_ami.debian12.id  
  instance_type   = "t2.micro"  
  subnet_id       = aws_subnet.main_subnet.id  
  key_name        = aws_key_pair.ec2_key_pair.key_name  
  security_groups = [aws_security_group.main_sg.name]

  associate_public_ip_address = true

  ...

  tags = {  
    Name = "${var.projeto}-${var.candidato}-sg"  
  }
```
* **`ami = data.aws_ami.debian12.id`**: Esta linha especifica a **Amazon Machine Image (AMI)** que será usada para lançar a instância EC2. A AMI está sendo buscada a partir do **data source** `data.aws_ami.debian12`.  
* **`instance_type = "t2.micro"`**: Define o tipo de instância EC2 que será utilizada. `t2.micro` é um tipo de instância de baixo custo.  
* **`subnet_id = aws_subnet.main_subnet.id`**: Associa a instância EC2 à sub-rede especificada. Isso significa que a instância será criada dentro da sub-rede na VPC.  
* **`key_name = aws_key_pair.ec2_key_pair.key_name`**: Define o **par de chaves** que será usado para acessar a instância via SSH.  
* **`security_groups = [aws_security_group.main_sg.name]`**: Especifica que a instância EC2 estará associada ao **Security Group** `main_sg`.
* **`associate_public_ip_address = true`**: Esta linha garante que a instância EC2 receba um **endereço IP público**, isso é importante para que você possa acessar a instância via SSH, por exemplo.
* **`tags {Name}`**: Adiciona uma tag ao Security Group com o nome baseado nas variáveis `projeto` e `candidato`.

### **Bloco `root_block_device` (Configuração de Disco)**
```
  root_block_device {  
    volume_size           = 20  
    volume_type           = "gp2"  
    delete_on_termination = true  
  }
```
Este bloco define as configurações para o **disco raiz** da instância EC2.

* **`volume_size = 20`**: Define o tamanho do volume raiz como **20 GB**.  
* **`volume_type = "gp2"`**: Especifica o tipo do volume como **gp2** (General Purpose SSD).  
* **`delete_on_termination = true`**: Define que o volume raiz será automaticamente **deletado quando a instância for terminada**.

### **Bloco `user_data`**
```
  user_data = <<-EOF  
              #!/bin/bash  
              apt-get update -y  
              apt-get upgrade -y  
              EOF
```
O campo `user_data` permite a execução de um script durante a inicialização da instância. Neste caso, o script é um simples **script bash** que atualiza e faz upgrade dos pacotes na instância Debian.

* **`#!/bin/bash`**: Indica que o script será executado no shell bash.  
* **`apt-get update -y`**: Atualiza os repositórios utilizados.
* **`apt-get upgrade -y`**: Atualiza todos os pacotes instalados para as versões mais recentes.

## Definição dos outputs

### **1\. Bloco `output "private_key"`**
```
output "private_key" {  
  description = "Chave privada para acessar a instância EC2"  
  value       = tls_private_key.ec2_key.private_key_pem  
  sensitive   = true  
}
```
* **`description = "Chave privada para acessar a instância EC2"`**: Fornece uma descrição explicando que este output contém a chave privada usada para acessar a instância EC2 via SSH.  
* **`value = tls_private_key.ec2_key.private_key_pem`**: Define o valor que será exibido. Nesse caso, a **chave privada** gerada pelo recurso `tls_private_key.ec2_key` (que foi criado anteriormente) será retornada. O campo `private_key_pem` contém a chave privada em formato PEM, usada para autenticação SSH.  
* **`sensitive = true`**: Este campo marca o output como **sensível**, o que significa que ele não será exibido diretamente no terminal para evitar que informações confidenciais, como a chave privada, sejam expostas publicamente.

### **2\. Bloco `output "ec2_public_ip"`**
```
output "ec2_public_ip" {  
  description = "Endereço IP público da instância EC2"  
  value       = aws_instance.debian_ec2.public_ip  
}
```
* **`description = "Endereço IP público da instância EC2"`**: Descrição explicando que este output contém o **endereço IP público** da instância EC2, permitindo que você a acesse diretamente pela internet.  
* **`value = aws_instance.debian_ec2.public_ip`**: O valor retornado é o **endereço IP público** da instância EC2.