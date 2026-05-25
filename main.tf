# Echo zeropoint module
#
# A minimal-but-real module that satisfies the zeropoint install
# contract end-to-end:
#
#   - runs an alpine container with busybox httpd serving the
#     greeting as plain text on port 8080
#   - declares that port through `main_ports` so the agent can
#     expose it via an Endpoint
#   - echoes the greeting back through outputs so the var →
#     terraform → output pipeline can be verified
#
# `curl http://<endpoint-name>.local/` returns the greeting once an
# http Endpoint has been created against `port_http`.

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
  description = "Message served by the container on GET /."
}

# ---- resources -------------------------------------------------------------

resource "docker_image" "alpine" {
  name         = "alpine:3.19"
  keep_locally = true
}

# Write the greeting to a file inside the container's /www, then
# run busybox httpd to serve it on :8080. Single-shot startup; no
# language runtime, no extra packages.
resource "docker_container" "main" {
  name    = "${var.zp_module_id}-main"
  image   = docker_image.alpine.image_id
  command = [
    "sh", "-c",
    "apk add --no-cache busybox-extras >/dev/null && mkdir -p /www && printf %s \"$GREETING\" > /www/index.html && exec busybox-extras httpd -f -p 8080 -h /www",
  ]
  env = [
    "GREETING=${var.greeting}",
  ]

  networks_advanced {
    name = var.zp_network_name
  }

  restart = "unless-stopped"
}

# ---- outputs ---------------------------------------------------------------

output "main" {
  value       = docker_container.main
  description = "Main alpine container."
}

# Ports declared by the main container. The agent's per-port sync
# turns each entry here into a `port_<name>` Var that users can
# expose via the picker.
output "main_ports" {
  value = {
    http = {
      port        = 8080
      protocol    = "http"
      transport   = "tcp"
      description = "Plain-text greeting served by busybox httpd."
      default     = true
    }
  }
  description = "Service ports for the main container."
}

# Echoes the configured greeting back as an output so the
# Var → output flow can be verified independently of HTTP.
output "greeting_echoed" {
  value       = var.greeting
  description = "Echoes the configured greeting; verifies user var → output flow."
}

output "container_name" {
  value       = docker_container.main.name
  description = "The actual container name resolved by docker."
}
