# Echo zeropoint module
#
# The smallest possible module that satisfies the zeropoint install
# contract. It runs an alpine container that echoes a greeting then
# sleeps, exposing the inputs back through outputs so the full
# var → terraform → output pipeline can be exercised.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# ---- system vars (injected by zeropoint) -----------------------------------

variable "zp_module_id" {
  type        = string
  description = "Unique identifier for this module instance (injected by zeropoint)."
}

variable "zp_network_name" {
  type        = string
  description = "Pre-created docker network for this module (injected by zeropoint)."
}

variable "zp_arch" {
  type        = string
  default     = "amd64"
  description = "Target CPU arch (injected by zeropoint)."
}

variable "zp_gpu_vendor" {
  type        = string
  default     = ""
  description = "GPU vendor (injected by zeropoint)."
}

variable "zp_module_dir" {
  type        = string
  description = "Agent's working directory for this module (injected by zeropoint). Terraform state and the cloned source live here. Users may edit this — the agent moves the directory atomically."
}

variable "zp_storage_dir" {
  type        = string
  description = "Isolated data root for this module (injected by zeropoint). All bind mounts MUST be under this path so the agent can move user data when zp_storage_dir is edited (atomic same-fs, rsync-and-swap cross-fs)."
}

# ---- user vars -------------------------------------------------------------

variable "greeting" {
  type        = string
  default     = "hello from zeropoint"
  description = "Message echoed by the container on startup."
}

variable "sleep_seconds" {
  type        = number
  default     = 86400
  description = "How long the container stays alive after greeting."
}

# ---- resources -------------------------------------------------------------

resource "docker_image" "alpine" {
  name         = "alpine:3.19"
  keep_locally = true
}

resource "docker_container" "main" {
  name    = "${var.zp_module_id}-main"
  image   = docker_image.alpine.image_id
  command = ["sh", "-c", "echo '${var.greeting}'; sleep ${var.sleep_seconds}"]

  networks_advanced {
    name = var.zp_network_name
  }

  restart = "unless-stopped"
}

# ---- outputs ---------------------------------------------------------------

# Required by the zeropoint contract: the primary container resource.
output "main" {
  value       = docker_container.main
  description = "Main alpine container."
}

# Required: ports declared by the main container. Echo has no real
# listener; we declare a placeholder to satisfy the contract.
output "main_ports" {
  value = {
    placeholder = {
      port        = 0
      protocol    = "tcp"
      transport   = "tcp"
      description = "Placeholder (echo has no real listener)."
      default     = true
    }
  }
  description = "Service ports for the main container."
}

# Echoes the configured greeting back as an output so the
# from_output VarNode pipeline can be verified end to end.
output "greeting_echoed" {
  value       = var.greeting
  description = "Echoes the configured greeting; verifies user var → output flow."
}

output "container_name" {
  value       = docker_container.main.name
  description = "The actual container name resolved by docker."
}
