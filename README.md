# Echo zeropoint module

A minimal-but-real test module for the [zeropoint](https://github.com/zeropoint-os/zeropoint) install contract. Spins up an `alpine:3.19` container running `busybox httpd` that serves the configured greeting as plain text on port 8080, and exposes its inputs back through outputs so the full `var → terraform → output → endpoint → envoy → mDNS` pipeline can be exercised end-to-end.

Used by [zeropoint-agent](https://github.com/zeropoint-os/zeropoint-agent) as the canonical bootstrap test module — a fresh devcontainer installs echo automatically so the install path is always covered.

## Resources Created

- **Docker Image**: `alpine:3.19` (kept locally)
- **Docker Container**: alpine running `busybox httpd -f -p 8080 -h /www`, with `/www/index.html` set to `<greeting>`

## End-to-end test

```bash
# expose port_http via the agent
curl -s -X POST http://localhost:2370/api/expose \
  -H 'Content-Type: application/json' \
  -d '{"port_var_id":"modules/echo/port_http"}'

# resolve from anywhere on the LAN
curl http://echo.local/      # → the configured greeting
```

## Requirements

- Terraform >= 1.0
- Docker provider ~> 3.0

## Usage

### Via zeropoint-agent

```bash
zeropoint-agent module add echo \
    https://github.com/zeropoint-os/echo.git@<sha> \
    --resolve
```

### Via REST

```bash
curl -X POST http://<zeropoint-node>:2370/api/modules \
  -H 'Content-Type: application/json' \
  -d '{
    "module_id": "echo",
    "source": "https://github.com/zeropoint-os/echo.git@<sha>",
    "resolve": true
  }'
```

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `zp_module_id` | string | Unique identifier for this module instance (injected by zeropoint). | (required) |
| `zp_network_name` | string | Pre-created docker network name (injected by zeropoint). | (required) |
| `zp_module_dir` | string | Agent's terraform working dir (injected by zeropoint). | (required) |
| `zp_storage_dir` | string | Module's isolated data root; use for all bind mounts (injected by zeropoint). | (required) |
| `zp_arch` | string | Target architecture (injected by zeropoint). | `"amd64"` |
| `zp_gpu_vendor` | string | GPU vendor (injected by zeropoint). | `""` |
| `greeting` | string | Message served by the container on GET /. | `"hello from zeropoint"` |

## Outputs

| Name | Description |
|------|-------------|
| `main` | The alpine container resource. |
| `main_ports` | Single `http` port (8080) served by busybox httpd. |
| `greeting_echoed` | The greeting passed back through, used to verify the user-var → output pipeline. |
| `container_name` | The container's actual name as resolved by docker. |

## Network & Service Discovery

- **Container Name**: `${zp_module_id}-main` (e.g. `echo-main`)
- **Network**: pre-created by zeropoint via `zp_network_name`
- **Container port**: 8080 (http). Exposed via the agent's `port_http` Var → Endpoint → Envoy → mDNS path.

## License

[Apache 2.0](LICENSE)
