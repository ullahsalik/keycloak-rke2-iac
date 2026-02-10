resource "null_resource" "rke2_install" {
  connection {
    type        = "ssh"
    host        = var.node_ip
    user        = var.ssh_user
    private_key = file(var.ssh_key)
  }

  provisioner "file" {
    source      = "${path.module}/install.sh"
    destination = "/tmp/install-rke2.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-rke2.sh",
      "sudo /tmp/install-rke2.sh"
    ]
  }
}

