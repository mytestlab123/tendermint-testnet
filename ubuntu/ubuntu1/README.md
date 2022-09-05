# Using scripts with provisioner & remote-exec 

### Install/Configure packages using "scripts"


```hcl

resource "aws_instance" "example" {
  key_name = data.aws_key_pair.this.key_name
  ami                         = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  security_groups = ["ubuntu-public"]
  tags = {
    Name = "ubuntu2"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/privatekey.pem")
    host = coalesce(self.public_ip, self.private_ip)
  }

  provisioner "remote-exec" {
    scripts = ["ubuntu.sh", "devops.sh"]
  }
}
```
