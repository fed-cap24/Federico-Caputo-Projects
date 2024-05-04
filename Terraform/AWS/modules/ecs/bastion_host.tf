## Create a public and private key pair for login to the ECS instances for the bastion Host

resource "tls_private_key" "ecs" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ecs" {
  key_name   = local.name-prefix != "" ? "${local.name-prefix}_ECS_Key" : "ECS_Key"
  public_key = tls_private_key.ecs.public_key_openssh
}

resource "null_resource" "configure_bastion_host" {
  triggers = {
    private_key = tls_private_key.ecs.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${tls_private_key.ecs.private_key_pem}' > /home/${var.bastion_host.user}/.ssh/id_rsa_ecs${local.name-posfix}",
      "chmod   600 /home/${var.bastion_host.user}/.ssh/id_rsa_ecs${local.name-posfix}",
      "if [ ! -f ~/.ssh/config ]; then",
      "  echo 'Host *' > ~/.ssh/config",
      "  echo '  IdentitiesOnly yes' >> ~/.ssh/config",
      "  echo '  IdentityFile ~/.ssh/id_rsa_ecs${local.name-posfix}' >> ~/.ssh/config",
      "else",
      "  grep -q 'IdentityFile ~/.ssh/id_rsa_ecs${local.name-posfix}' ~/.ssh/config || echo '  IdentityFile ~/.ssh/id_rsa_ecs${local.name-posfix}' >> ~/.ssh/config",
      "fi"
    ]

    connection {
      type        = "ssh"
      user        = var.bastion_host.user
      private_key = file(var.bastion_host.private_key_path)
      host        = var.bastion_host.public_ip
      timeout     = "5m"
    }
  }
}