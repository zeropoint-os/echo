# Echo zeropoint module

The smallest possible module that satisfies the [zeropoint](https://github.com/zeropoint-os/zeropoint) install contract. Spins up an `alpine:3.19` container that echoes a greeting then sleeps, and exposes its inputs back through outputs so the full `var → terraform → output` pipeline can be exercised.

Used by [zeropoint-agent](https://github.com/zeropoint-os/zeropoint-agent) as the canonical bootstrap test module — a fresh devcontainer installs echo automatically so the install path is always covered.

## Resources Created

- **Docker Image**: `alpine:3.19` (kept locally)
- **Docker Container**: alpine running `echo '<greeting>' && sleep <sleep_seconds>`

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
| `greeting` | string | Message echoed by the container on startup. | `"hello from zeropoint"` |
| `sleep_seconds` | number | How long the container stays alive after greeting. | `86400` |

## Outputs

| Name | Description |
|------|-------------|
| `main` | The alpine container resource. |
| `main_ports` | Placeholder (echo has no real listener). |
| `greeting_echoed` | The greeting passed back through, used to verify the user-var → output pipeline. |
| `container_name` | The container's actual name as resolved by docker. |

## Network & Service Discovery

- **Container Name**: `${zp_module_id}-main` (e.g. `echo-main`)
- **Network**: pre-created by zeropoint via `zp_network_name`
- **No Host Ports**: echo doesn't listen on anything — the `placeholder` port satisfies the contract requirement.

## License

[Apache 2.0](LICENSE)
