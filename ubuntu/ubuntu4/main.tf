provider "aws" {
  region = local.region
}

locals {
  name   = replace(basename(path.cwd), "_", "-")
  env    = "mint"
  region = "us-east-1"

  tags = {
    Project    = local.name
    # GithubRepo = "mytestlab123/tendermint-testnet"
  }
}

resource "aws_instance" "this" {
  key_name = data.aws_key_pair.this.key_name
  # https://cloud-images.ubuntu.com/locator/ec2/ | ap-east-1 | Ubuntu 20.04 LTS
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.medium"
  security_groups = ["ubuntu-public"]
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    throughput  = 200
    volume_size = 100
    tags = {
      Name = "my-root-block"
    }
  }
  tags = {
    Name = "${local.env}-${local.name}"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/bastion_public_key.pem")
    host        = coalesce(self.public_ip, self.private_ip)
  }

  provisioner "local-exec" {
    command = "curl -s -o scripts/cosmos.sh https://raw.githubusercontent.com/amitkarpe/setup/main/scripts/cosmos.sh;" 
  }

  provisioner "remote-exec" {
    scripts = ["scripts/cosmos.sh"] 
  }
}

data "aws_key_pair" "this" {
  key_name           = "bastion_public_key"
  include_public_key = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

output "run" {
  value = "export host=$(tf show | grep -i public_dns | awk {'print $3'} | sed 's/\"//g'); echo $host; ssh ubuntu@$host; curl -s -I $host | grep HTTP"
}
output "ip" {
  value = aws_instance.this.public_ip
}
