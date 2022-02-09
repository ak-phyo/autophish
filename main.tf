terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

resource "aws_instance" "basic_ec2" {
  ami                         = "ami-0367b500fdcac0edc"
  count                       = 1
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.secgroup.id]
  key_name                    = "privatekeyname"
  associate_public_ip_address = "true"
  root_block_device {
    volume_size = "25"
  }
  user_data = <<-EOF
#!/bin/bash
sudo apt update -y &>> /tmp/log
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade &>> /tmp/log
echo "postfix postfix/mailname string example.com" | debconf-set-selections 
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
sudo apt install -y postfix unzip golang-go sqlite 
sudo wget https://github.com/gophish/gophish/releases/download/v0.11.0/gophish-v0.11.0-linux-64bit.zip -O /opt/gophish.zip
cd /opt && sudo unzip gophish.zip -d /opt/gophish
sudo sed -i 's/127.0.0.1:3333/0.0.0.0:5000/' /opt/gophish/config.json
sudo sed -i 's/"filename": ""/"filename": "gophish.log"/' /opt/gophish/config.json
sudo sed -i 's/0.0.0.0:80/0.0.0.0:443/' /opt/gophish/config.json
sudo sed -i 's/"use_tls": false/"use_tls": true/' /opt/gophish/config.json
sudo chmod +x /opt/gophish/gophish
cd /opt/gophish
echo '#!/bin/bash

tmux new-session -d -s test "cd /opt/gophish && ./gophish"' > /opt/gophish_run.sh
chmod +x /opt/gophish_run.sh
sudo echo '@reboot root /opt/gophish_run.sh' >> /etc/crontab
/opt/gophish_run.sh

sleep 60
sudo sqlite3 /opt/gophish/gophish.db "insert into users("id","username","hash","api_key","role_id","password_change_required") Values ('2','testuser','\$2a\$<REDACTED>qVdEOasm','7dd7f201373<REDACTED>45b5124b120','1','0');"
sudo sqlite3 /opt/gophish/gophish.db "update users set hash='\$2a\$<REDACTED>qVdEOasm',password_change_required=0 where id=1;"

echo "[email-smtp.us-west-2.amazonaws.com]:465 AKIA3EQ2GKLMW<REDACTED>n678FAdHJ" | sudo tee /etc/postfix/sasl_passwd     
sudo postmap /etc/postfix/sasl_passwd
sudo postfix reload
sudo sed -i 's/relayhost =/relayhost = [email-smtp.us-west-2.amazonaws.com]:465/' /etc/postfix/main.cf
sudo echo 'default_destination_rate_delay=2m smtp_sasl_auth_enable=yes smtp_sasl_security_options=noanonymous smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd smtp_use_tls=yes smtp_tls_wrappermode=yes smtp_tls_security_level=encrypt smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt' | sudo tr " " "\n" | sudo tee -a /etc/postfix/main.cf

sudo hostname -f > /etc/mailname
sudo hostname -f > /etc/hostname
sudo timedatectl set-timezone Asia/Yangon
sudo systemctl restart postfix

EOF
  tags = {
    Name = "Server_testing_${count.index}"
  }
}

output "public_ip" {
  value = aws_instance.basic_ec2.*.public_ip
}

resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "secgroup" {
  name        = "testing_rules"
  description = "ingress egress for phishing"
  vpc_id      = aws_default_vpc.default.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
