# This code is a definition of the default region location, 
# where will be activated the whole setup.

variable "profile" {
  default = "default"
}

variable "region" {
  default = "eu-west-3"
}

variable "bucket" {
  default = "radi-tf-state"
}

variable "acl" {
  default = "private"
}