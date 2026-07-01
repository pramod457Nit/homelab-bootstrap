# Installation

## Option 1: Clone manually

```bash
git clone https://github.com/pramod457Nit/homelab-bootstrap.git
cd homelab-bootstrap
./bootstrap.sh doctor
```

## Option 2: Install command

```bash
curl -fsSL https://raw.githubusercontent.com/pramod457Nit/homelab-bootstrap/main/install.sh | bash
```

Then run:

```bash
homelab-bootstrap doctor
```

## Safety

The installer only:

- Clones or updates the repo
- Creates a symlink in ~/.local/bin
- Runs doctor

It does not:

- Change firewall rules
- Install packages
- Configure SSH
- Connect Azure
- Apply updates
