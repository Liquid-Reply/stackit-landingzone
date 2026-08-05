variable "name" {
  type        = string
  description = "Folder name"
}

variable "parent_container_id" {
  type        = string
  description = "Parent organization or folder container ID"
}

variable "owner_email" {
  type        = string
  description = "Folder owner email address"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to attach to the folder"
}
