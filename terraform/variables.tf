variable "node_ip" {
  description = "The ip of the virtual machine in which RKE2 will be hosted"
  type        = string
}

variable "ssh_user" {
  description = "The username of the virtual machine in which RKE2 will be hosted"
  type        = string
}

variable "ssh_key_path" {
  description = "Path to the private SSH key file used for authentication"
  type        = string
  default     = "~/.ssh/id_rsa"
}