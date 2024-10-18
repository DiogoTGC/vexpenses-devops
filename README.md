# Explicação main.tf

## Definição do provedor e variáveis

Vamos fazer uma análise detalhada desse código Terraform.

### **1\. Bloco `provider`**

  
```
provider "aws" {  
  region = "us-east-1"  
}
```

Este bloco define o **provedor** que o Terraform usará para interagir com a infraestrutura da AWS (Amazon Web Services). O Terraform usa **provedores** para saber como se comunicar com os serviços da nuvem, como a AWS, GCP, Azure, etc.

* **"aws"**: Este é o nome do provedor (AWS neste caso).  
* **`region = "us-east-1"`**: Define a região da AWS onde os recursos serão criados. A região "us-east-1" se refere à região da Virgínia do Norte.

### **2\. Bloco `variable "projeto"`**

  
```
variable "projeto" {  
  description = "Nome do projeto"  
  type        = string  
  default     = "VExpenses"  
}
```

Este bloco define uma **variável** chamada `projeto`. Variáveis em Terraform são usadas para parametrizar a infraestrutura, permitindo reutilização e flexibilidade no código.

* **`description`**: Explica o propósito da variável, que aqui é "Nome do projeto".  
* **`type = string`**: Define o tipo de dado da variável como `string` (cadeia de caracteres).  
* **`default = "VExpenses"`**: Especifica um valor padrão para a variável, no caso "VExpenses". Se o valor não for passado explicitamente, o Terraform usará este valor.

### **3\. Bloco `variable "candidato"`**

  
```
variable "candidato" {  
  description = "Nome do candidato"  
  type        = string  
  default     = "SeuNome"  
}
```

Este bloco também define uma **variável**, mas agora com o nome `candidato`.

* **`description`**: "Nome do candidato" descreve que essa variável representa o nome de um candidato (provavelmente de uma pessoa executando ou usando o projeto).  
* **`type = string`**: Novamente, o tipo de dado é `string`.  
* **`default = "SeuNome"`**: Define "SeuNome" como valor padrão. Quem for usar o código Terraform pode alterar esse valor conforme necessário.

### **Conclusão:**

Este código define a configuração inicial para criar infraestrutura na AWS usando Terraform. Ele:

1. Especifica a região da AWS como "us-east-1".  
2. Define duas variáveis:  
   * `projeto`, com um valor padrão de "VExpenses".  
   * `candidato`, com um valor padrão de "SeuNome".

Essas variáveis podem ser usadas posteriormente no código Terraform para nomear ou configurar recursos, permitindo que o projeto seja parametrizável e adaptável a diferentes cenários.

## Definição de um provedor e a criação da chave SSH

Vamos analisar os novos blocos de código Terraform que você enviou, que tratam da criação de uma chave SSH para uso na AWS.

### **1\. Bloco `resource "tls_private_key" "ec2_key"`**

  
```
resource "tls_private_key" "ec2_key" { 
  algorithm = "RSA"
  rsa_bits  = 2048
}
```

Este bloco define um **recurso** chamado `tls_private_key`, que é um **provedor** específico para gerar chaves criptográficas TLS (Transport Layer Security). A chave gerada será utilizada, por exemplo, para acessar instâncias EC2 na AWS. No caso, uma chave privada para autenticação SSH será criada.

* **`algorithm = "RSA"`**: Define que o algoritmo usado para gerar a chave será o **RSA** (Rivest–Shamir–Adleman), um algoritmo criptográfico amplamente usado para criar chaves públicas e privadas.  
* **`rsa_bits = 2048`**: Especifica o tamanho da chave RSA em bits. Neste caso, será gerada uma chave de 2048 bits, que oferece um bom equilíbrio entre segurança e performance.

Esse recurso criará uma chave privada que será usada localmente, e uma chave pública associada que será usada pela AWS.

### **2\. Bloco `resource "aws_key_pair" "ec2_key_pair"`**

  
```
resource "aws_key_pair" "ec2_key_pair" {  
  key_name   = "${var.projeto}-${var.candidato}-key"  
  public_key = tls_private_key.ec2_key.public_key_openssh  
}
```

Este bloco define um recurso da AWS chamado `aws_key_pair`, que cria um **par de chaves** SSH na AWS. Ele associa a chave pública gerada anteriormente ao serviço da AWS (EC2, por exemplo), permitindo que essa chave seja usada para acessar instâncias da EC2 por SSH.

* **`key_name = "${var.projeto}-${var.candidato}-key"`**: Define o nome do par de chaves. Aqui, o nome é composto pela concatenação dos valores das variáveis `projeto` e `candidato`, seguidos de `-key`. Por exemplo, se o projeto for "VExpenses" e o candidato for "SeuNome", o nome do par de chaves será **"VExpenses-SeuNome-key"**.  
  * `${var.projeto}` e `${var.candidato}` são placeholders para referenciar o valor das variáveis `projeto` e `candidato`, respectivamente.  
* **`public_key = tls_private_key.ec2_key.public_key_openssh`**: Atribui a chave pública gerada pelo recurso `tls_private_key` (referenciado como `tls_private_key.ec2_key`) ao par de chaves AWS. O atributo `public_key_openssh` fornece a chave pública no formato compatível com OpenSSH, que é o formato esperado pela AWS.

### **Conclusão:**

Este código cria:

1. Um par de chaves RSA usando o recurso `tls_private_key` para gerar uma chave privada de 2048 bits.  
2. Um recurso `aws_key_pair`, que associa a chave pública gerada ao serviço AWS EC2, com um nome de chave que é composto das variáveis `projeto` e `candidato`.

Esse par de chaves pode ser usado para acessar instâncias EC2 via SSH. A chave privada ficará localmente, enquanto a chave pública será associada às instâncias EC2 na AWS para fins de autenticação.

## Criação de uma VPC, subnet e gateway

Esse trecho de código Terraform está criando uma infraestrutura de rede na AWS. Ele define uma VPC (Virtual Private Cloud), uma sub-rede dentro dessa VPC, e um gateway de internet. Vamos analisar cada recurso em detalhes.

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

Este bloco cria uma **VPC** (Virtual Private Cloud) na AWS, que é uma rede virtual isolada onde você pode executar seus recursos da nuvem, como instâncias EC2.

* **`cidr_block = "10.0.0.0/16"`**: Define o bloco CIDR (Classless Inter-Domain Routing) da VPC, que é o intervalo de endereços IP para essa rede. O bloco `10.0.0.0/16` permite um total de 65.536 endereços IP (de 10.0.0.0 a 10.0.255.255).  
* **`enable_dns_support = true`**: Ativa o suporte a DNS dentro da VPC, permitindo que os recursos dentro dela resolvam nomes de domínio.  
* **`enable_dns_hostnames = true`**: Habilita a atribuição de nomes DNS públicos para os recursos da VPC, como instâncias EC2, para que eles possam ser acessados por um nome, além do endereço IP.  
* **`tags`**: Adiciona tags à VPC. O nome da tag será uma combinação das variáveis `projeto` e `candidato`. Por exemplo, o nome da VPC pode ser algo como **"VExpenses-SeuNome-vpc"**.

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

* **`vpc_id = aws_vpc.main_vpc.id`**: Associa a sub-rede à VPC criada anteriormente, referenciada aqui pelo identificador da VPC (`aws_vpc.main_vpc.id`).  
* **`cidr_block = "10.0.1.0/24"`**: Define o bloco CIDR da sub-rede. O intervalo `10.0.1.0/24` permite até 256 endereços IP (de 10.0.1.0 a 10.0.1.255), que serão usados para alocar IPs para recursos como instâncias EC2.  
* **`availability_zone = "us-east-1a"`**: Especifica que a sub-rede será criada na zona de disponibilidade "us-east-1a". Zonas de disponibilidade são regiões físicas independentes dentro de uma região da AWS.  
* **`tags`**: Adiciona tags à sub-rede, nomeando-a também com base nas variáveis `projeto` e `candidato`, algo como **"VExpenses-SeuNome-subnet"**.

### **3\. Bloco `resource "aws_internet_gateway" "main_igw"`**

  
```
resource "aws_internet_gateway" "main_igw" {  
  vpc_id = aws_vpc.main_vpc.id

  tags = {  
    Name = "${var.projeto}-${var.candidato}-igw"  
  }  
}
```

Este bloco cria um **Internet Gateway** (IGW), que é um ponto de entrada e saída da internet para a VPC. Ele permite que instâncias dentro da VPC se comuniquem com a internet, como servidores web.

* **`vpc_id = aws_vpc.main_vpc.id`**: Associa o Internet Gateway à VPC criada anteriormente (`aws_vpc.main_vpc`).  
* **`tags`**: Adiciona tags ao Internet Gateway, nomeando-o com base nas variáveis `projeto` e `candidato`, algo como **"VExpenses-SeuNome-igw"**.

### **Conclusão:**

Este código cria os seguintes recursos de rede na AWS:

1. **VPC (aws\_vpc.main\_vpc)**: Uma rede privada virtual com o bloco de endereços IP `10.0.0.0/16`.  
2. **Sub-rede (aws\_subnet.main\_subnet)**: Uma sub-rede dentro da VPC, com o bloco de endereços `10.0.1.0/24`, localizada na zona de disponibilidade "us-east-1a".  
3. **Internet Gateway (aws\_internet\_gateway.main\_igw)**: Um gateway que permite que os recursos da VPC se comuniquem com a internet.

As tags aplicadas em todos os recursos seguem o padrão `projeto-candidato`, o que facilita a identificação e organização dos recursos na AWS.

###### 

## Criação da tabela de rotas e associação a subnet

Este trecho de código adiciona uma **tabela de rotas** à VPC e associa essa tabela à sub-rede criada anteriormente. Vamos explicar o funcionamento de cada recurso:

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

Este bloco cria uma **tabela de rotas** para a VPC, que define como o tráfego será roteado entre a VPC e outros destinos, como a internet.

* **`vpc_id = aws_vpc.main_vpc.id`**: Associa a tabela de rotas à VPC criada anteriormente, referenciada pelo ID da VPC.  
* **`route`**: Dentro do bloco `route`, é configurada uma rota específica.  
  * **`cidr_block = "0.0.0.0/0"`**: Define o bloco CIDR para a rota, onde `0.0.0.0/0` representa "qualquer destino na internet" (ou seja, o tráfego para qualquer IP fora da rede privada).  
  * **`gateway_id = aws_internet_gateway.main_igw.id`**: Define que o tráfego com destino à internet (conforme definido pelo CIDR `0.0.0.0/0`) será roteado através do **Internet Gateway** (IGW) criado anteriormente (`aws_internet_gateway.main_igw.id`).  
* **`tags`**: Adiciona uma tag à tabela de rotas, nomeando-a com base nas variáveis `projeto` e `candidato`, algo como **"VExpenses-SeuNome-route\_table"**.

#### **Resumo:**

Esta tabela de rotas permite que o tráfego originado de instâncias dentro da VPC seja roteado para a internet através do Internet Gateway. A rota `0.0.0.0/0` direciona todo o tráfego externo para o IGW.

### **2\. Bloco `resource "aws_route_table_association" "main_association"`**

  
```
resource "aws_route_table_association" "main_association" {  
  subnet_id      = aws_subnet.main_subnet.id  
  route_table_id = aws_route_table.main_route_table.id

  tags = {  
    Name = "${var.projeto}-${var.candidato}-route_table_association"  
  }  
}
```

Este bloco associa a **tabela de rotas** criada anteriormente à **sub-rede** dentro da VPC. A associação entre sub-rede e tabela de rotas é necessária para que o tráfego da sub-rede siga as rotas definidas.

* **`subnet_id = aws_subnet.main_subnet.id`**: Identifica a sub-rede que será associada à tabela de rotas, que no caso é a sub-rede criada anteriormente (`aws_subnet.main_subnet.id`).  
* **`route_table_id = aws_route_table.main_route_table.id`**: Identifica a tabela de rotas que será associada à sub-rede, neste caso, a tabela de rotas criada anteriormente (`aws_route_table.main_route_table.id`).  
* **`tags`**: Adiciona tags à associação da tabela de rotas, também utilizando as variáveis `projeto` e `candidato`, algo como **"VExpenses-SeuNome-route\_table\_association"**.

#### **Resumo:**

Esta associação garante que o tráfego da sub-rede **"10.0.1.0/24"** siga as rotas definidas pela tabela de rotas, permitindo que as instâncias nessa sub-rede tenham acesso à internet (via o Internet Gateway).

### **Conclusão:**

Este código cria:

1. **Tabela de Rotas (aws\_route\_table.main\_route\_table)**: Define as regras de roteamento para a VPC. Neste caso, todo o tráfego destinado à internet (`0.0.0.0/0`) será direcionado através do Internet Gateway.  
2. **Associação de Tabela de Rotas (aws\_route\_table\_association.main\_association)**: Associa a tabela de rotas à sub-rede criada anteriormente, para que as instâncias na sub-rede sigam as regras de roteamento (incluindo o acesso à internet).

Com isso, a sub-rede criada terá conectividade com a internet por meio da tabela de rotas e do Internet Gateway, permitindo que instâncias EC2 na sub-rede façam solicitações externas, como acessar websites ou APIs externas.

## Criação do security group

Este bloco de código Terraform cria um **Security Group** (grupo de segurança) na AWS, que é um conjunto de regras que controla o tráfego de rede de entrada e saída para as instâncias dentro da VPC. Vamos analisar o código detalhadamente.

### **Bloco `resource "aws_security_group" "main_sg"`**

  
```
resource "aws_security_group" "main_sg" {  
  name        = "${var.projeto}-${var.candidato}-sg"  
  description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"  
  vpc_id      = aws_vpc.main_vpc.id
```

Este bloco cria um **Security Group** associado à VPC especificada. O **Security Group** controla o tráfego que é permitido entrar e sair de recursos como instâncias EC2.

* **`name = "${var.projeto}-${var.candidato}-sg"`**: Define o nome do Security Group, que é composto pelas variáveis `projeto` e `candidato`, por exemplo, **"VExpenses-SeuNome-sg"**.  
* **`description = "Permitir SSH de qualquer lugar e todo o tráfego de saída"`**: Uma descrição breve que explica que o grupo de segurança permitirá conexões SSH de qualquer local e permitirá qualquer tráfego de saída.  
* **`vpc_id = aws_vpc.main_vpc.id`**: Associa o Security Group à VPC criada anteriormente, usando o ID da VPC.

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
* **\`cidr\_blocks \= \["0.0.0.0/0"\]**: Permite o tráfego de qualquer endereço IPv4, já que o bloco CIDR "0.0.0.0/0" significa "qualquer origem".  
* **\`ipv6\_cidr\_blocks \= \["::/0"\]**: Permite o tráfego de qualquer endereço IPv6.

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
* **\`cidr\_blocks \= \["0.0.0.0/0"\]** Permite que o tráfego de saída vá para qualquer endereço IPv4.  
* **\`ipv6\_cidr\_blocks \= \["::/0"\]** Permite que o tráfego de saída vá para qualquer endereço IPv6.

Esta regra permite que as instâncias na VPC possam se comunicar com qualquer endereço IP na internet, independentemente do protocolo ou porta.

### **Tags**

  
 ```
  tags = {  
    Name = "${var.projeto}-${var.candidato}-sg"  
  }
  ```

* **`tags`**: Adiciona uma tag ao Security Group com o nome baseado nas variáveis `projeto` e `candidato`, algo como **"VExpenses-SeuNome-sg"**. Isso facilita a identificação e organização dos recursos na AWS.

### **Conclusão:**

Este código cria um **Security Group** que:

1. **Permite o tráfego de entrada na porta 22 (SSH)** de qualquer local, tanto em IPv4 quanto em IPv6. Isso permite que as instâncias EC2 sejam acessadas via SSH de qualquer lugar.  
2. **Permite todo o tráfego de saída**, ou seja, as instâncias associadas a esse Security Group podem se comunicar com qualquer destino na internet, sem restrição de protocolo, porta ou destino.

Esse Security Group é útil para instâncias EC2 que precisam ser acessadas remotamente via SSH e que precisam se comunicar livremente com a internet.

###### 

## Definição de uma AMI (Máquina Virtual pré-configurada)

Este bloco de código define um **data source** no Terraform, que consulta e recupera informações sobre uma **Amazon Machine Image (AMI)** no serviço EC2 da AWS. AMIs são imagens pré-configuradas que podem ser usadas para lançar instâncias EC2, como servidores com sistemas operacionais e software instalados. Vamos detalhar o que cada parte do código faz.

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

Este bloco de código consulta a AWS para recuperar uma AMI específica com base em certos filtros e critérios. O data source `aws_ami` é útil quando você quer garantir que está sempre usando a versão mais recente de uma imagem específica, ou quando precisa referenciar uma AMI específica sem fornecer um ID fixo.

### **Campos explicados:**

* **`most_recent = true`**: Este parâmetro diz ao Terraform para buscar a AMI mais recente que corresponda aos filtros especificados. Isso garante que você esteja utilizando a versão mais atualizada da imagem Debian 12\.

### **1\. Bloco `filter` (Filtro de nome)**

  
```
  filter {  
    name   = "name"  
    values = ["debian-12-amd64-*"]  
  }
```

Este filtro define que a consulta irá buscar por AMIs cujo **nome** corresponda ao padrão `"debian-12-amd64-*"`. O caractere `"*"` é um curinga, o que significa que qualquer nome de AMI que comece com `"debian-12-amd64-"` será considerado.

O formato `"debian-12-amd64-*"` sugere que o objetivo é encontrar uma imagem do sistema operacional **Debian 12** para a arquitetura **AMD64** (64-bit).

### **2\. Bloco `filter` (Filtro de tipo de virtualização)**

  
```
  filter { 
    name   = "virtualization-type"  
    values = ["hvm"]  
  }
```

Este filtro define que a AMI deve ser compatível com a **virtualização do tipo HVM (Hardware Virtual Machine)**, que é o tipo de virtualização mais comum e recomendada para executar instâncias EC2 modernas. O tipo HVM utiliza a aceleração de hardware disponível em servidores mais recentes para melhorar o desempenho.

### **3\. Bloco `owners`**

  
 ```
 owners = ["679593333241"]
 ```

Este campo especifica o ID do proprietário das AMIs que devem ser consideradas. Neste caso, o ID `"679593333241"` pertence à equipe oficial que mantém as AMIs do **Debian** na AWS. Isso garante que as AMIs retornadas sejam oficialmente fornecidas e mantidas pela equipe Debian.

### **Conclusão:**

Este código consulta a AWS em busca da AMI mais recente que atenda aos seguintes critérios:

1. **Debian 12** (arquitetura AMD64) com o nome que segue o padrão `"debian-12-amd64-*"`.  
2. **Virtualização do tipo HVM**.  
3. **Mantida pelo proprietário oficial do Debian**, identificado pelo ID `"679593333241"`.

Esse **data source** pode ser referenciado em outros recursos Terraform, como na criação de uma instância EC2, para garantir que a instância seja lançada com a versão mais recente da imagem Debian 12\.

## Definição do EC2

Este bloco de código define uma **instância EC2** na AWS com base na AMI do Debian 12 e configurações adicionais. Vamos explicar cada parte do recurso:

### **Bloco `resource "aws_instance" "debian_ec2"`**

  
```
resource "aws_instance" "debian_ec2" {  
  ami             = data.aws_ami.debian12.id  
  instance_type   = "t2.micro"  
  subnet_id       = aws_subnet.main_subnet.id  
  key_name        = aws_key_pair.ec2_key_pair.key_name  
  security_groups = [aws_security_group.main_sg.name]
```

* **`ami = data.aws_ami.debian12.id`**: Esta linha especifica a **Amazon Machine Image (AMI)** que será usada para lançar a instância EC2. A AMI está sendo buscada a partir do **data source** `data.aws_ami.debian12`, que recupera a AMI mais recente do Debian 12\. O valor `data.aws_ami.debian12.id` referenciará o ID da AMI.  
* **`instance_type = "t2.micro"`**: Define o tipo de instância EC2 que será utilizada. `t2.micro` é um tipo de instância de baixo custo, elegível para o **nível gratuito da AWS** (AWS Free Tier), e é adequado para cargas de trabalho leves, como servidores de teste ou pequenos websites.  
* **`subnet_id = aws_subnet.main_subnet.id`**: Associa a instância EC2 à sub-rede especificada, que é a sub-rede criada anteriormente no recurso `aws_subnet.main_subnet`. Isso significa que a instância será criada dentro da sub-rede na VPC.  
* **`key_name = aws_key_pair.ec2_key_pair.key_name`**: Define o **par de chaves** que será usado para acessar a instância via SSH. O par de chaves foi criado anteriormente como `aws_key_pair.ec2_key_pair`.  
* **`security_groups = [aws_security_group.main_sg.name]`**: Especifica que a instância EC2 estará associada ao **Security Group** `main_sg`. Este grupo de segurança permitirá, por exemplo, acesso SSH (porta 22\) de qualquer local, conforme configurado anteriormente.

### **Configuração de Endereço IP Público**

  
 `associate_public_ip_address = true`

Esta linha garante que a instância EC2 receba um **endereço IP público**, permitindo que ela seja acessada diretamente da internet. Isso é importante para que você possa acessar a instância via SSH, por exemplo.

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
* **`volume_type = "gp2"`**: Especifica o tipo do volume como **gp2** (General Purpose SSD), que é adequado para a maioria das cargas de trabalho com desempenho equilibrado.  
* **`delete_on_termination = true`**: Define que o volume raiz será automaticamente **deletado quando a instância for terminada** (deletada). Isso ajuda a evitar custos adicionais de armazenamento após a instância ser removida.

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
* **`apt-get update -y`**: Atualiza a lista de pacotes disponíveis.  
* **`apt-get upgrade -y`**: Atualiza todos os pacotes instalados para as versões mais recentes.

Este script garante que, ao iniciar, a instância esteja com todos os pacotes de software atualizados.

### **Bloco `tags`**

  
```
  tags = {  
    Name = "${var.projeto}-${var.candidato}-ec2"  
  }
```

As **tags** são usadas para nomear a instância EC2 e facilitar a organização dos recursos na AWS.

* O nome será baseado nas variáveis `projeto` e `candidato`, resultando em algo como **"VExpenses-SeuNome-ec2"**.

### **Conclusão:**

Este código configura e lança uma instância EC2 com a AMI mais recente do **Debian 12**, com as seguintes características:

1. Tipo de instância **t2.micro**, adequado para cargas de trabalho leves e elegível para o AWS Free Tier.  
2. Associada a uma sub-rede específica e um **Security Group** que permite SSH.  
3. Recebe um **endereço IP público** para que possa ser acessada via SSH.  
4. O disco raiz tem 20 GB e será excluído quando a instância for terminada.  
5. Ao iniciar, a instância executa um script que atualiza os pacotes do sistema operacional.

## Definição dos outputs

Este bloco de código define **outputs** no Terraform, que são valores retornados ao final da execução do plano. Esses valores permitem acessar facilmente informações específicas sobre os recursos provisionados, sem precisar navegar pela interface da AWS. Vamos analisar cada parte do código.

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
* **`sensitive = true`**: Este campo marca o output como **sensível**, o que significa que ele não será exibido diretamente no terminal para evitar que informações confidenciais, como a chave privada, sejam expostas publicamente. Isso é importante por motivos de segurança.

#### **Resumo:**

Este output fornece a **chave privada** para acessar a instância EC2 via SSH, mas marca essa chave como sensível, para que ela não seja exibida diretamente na saída do Terraform.

### **2\. Bloco `output "ec2_public_ip"`**

  
```
output "ec2_public_ip" {  
  description = "Endereço IP público da instância EC2"  
  value       = aws_instance.debian_ec2.public_ip  
}
```

* **`description = "Endereço IP público da instância EC2"`**: Descrição explicando que este output contém o **endereço IP público** da instância EC2, permitindo que você a acesse diretamente pela internet.  
* **`value = aws_instance.debian_ec2.public_ip`**: O valor retornado é o **endereço IP público** da instância EC2, obtido a partir do recurso `aws_instance.debian_ec2`. Este campo (`public_ip`) contém o endereço público associado à instância.

#### **Resumo:**

Este output fornece o **endereço IP público** da instância EC2. Com esse valor, você poderá se conectar à instância, por exemplo, usando um cliente SSH.

### **Conclusão:**

Este código define dois outputs no Terraform:

1. **`private_key`**: Retorna a **chave privada** gerada para acessar a instância via SSH, mas com a marcação `sensitive = true` para não exibir a chave diretamente.  
2. **`ec2_public_ip`**: Retorna o **endereço IP público** da instância EC2, permitindo fácil acesso à instância pela internet.

Com esses outputs, você pode copiar a chave privada para se conectar à instância e usar o endereço IP público para acessá-la.

