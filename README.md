# homelab-bootstrap

A secure, Azure-managed hybrid homelab reference implementation for Ubuntu, Docker, NVIDIA GPU, Azure Arc, Azure Monitor, Tailscale, and self-hosting.

## Goal

Bootstrap and validate a production-style Ubuntu homelab or AI workstation with secure remote access, observability, governance, and recovery practices.

## Core Features

- Ubuntu security baseline
- SSH, UFW, Fail2Ban
- Docker and Docker Compose
- NVIDIA GPU and Docker GPU validation
- Tailscale remote access
- Azure Arc onboarding guidance
- Azure Monitor guidance
- Update Manager guidance
- Cost guardrails
- Doctor and verification commands
- Public-repo-safe configuration model
- No secrets committed to Git

## Quick Start

```bash
git clone https://github.com/<your-user>/homelab-bootstrap.git
cd homelab-bootstrap
./bootstrap.sh doctor

## GPU Behavior

NVIDIA GPU support is optional.

If an NVIDIA GPU is detected, `doctor` validates:

- NVIDIA hardware detection
- `nvidia-smi`

If no NVIDIA GPU is detected, GPU checks are skipped instead of failing. This allows the repo to work on both GPU and non-GPU Ubuntu homelabs.
