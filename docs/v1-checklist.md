# V1 checklist

This repo is considered V1-ready when the following installed commands pass:

```bash
homelab-bootstrap doctor
homelab-bootstrap docker --verify
homelab-bootstrap nvidia --verify
homelab-bootstrap tailscale --verify
homelab-bootstrap azure-arc --verify
homelab-bootstrap azure-monitor --verify

Safety rules:

No secrets in the repo.
No Tailscale auth keys in the repo.
No Azure service principal secrets in the repo.
NVIDIA module verifies only; it does not install drivers.
Azure modules verify only; they do not onboard or create cloud resources.
Docker user group access is optional because it is root-equivalent.
