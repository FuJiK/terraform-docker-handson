#!/usr/bin/env python3
"""Generate a local Ansible inventory from Terraform output (no PyYAML dependency)."""
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INVENTORY = Path(__file__).resolve().parent / "inventory" / "hosts.json"

def output(name, values):
    value = values.get(name, {}).get("value")
    if not value:
        raise SystemExit(f"Missing Terraform output {name!r}. Apply with enable_wordpress_lab=true first.")
    return value

def main():
    values = json.loads(subprocess.check_output(["terraform", "output", "-json"], cwd=ROOT, text=True))
    public_ip = output("web_public_ip", values)
    web_private_ip = output("web_private_ip", values)
    db_private_ip = output("db_private_ip", values)
    hosts = {
        "all": {
            "vars": {"ansible_user": "ubuntu"},
            "children": {
                "web": {
                    "hosts": {
                        "web": {
                            "ansible_host": public_ip,
                            "private_ip": web_private_ip,
                            "wordpress_url": f"http://{public_ip}",
                        }
                    }
                },
                "db": {
                    "hosts": {
                        "db": {
                            "ansible_host": db_private_ip,
                            "private_ip": db_private_ip,
                            "ansible_ssh_common_args": f"-o ProxyJump=ubuntu@{public_ip}",
                        }
                    }
                },
            },
        }
    }
    INVENTORY.parent.mkdir(parents=True, exist_ok=True)
    INVENTORY.write_text(json.dumps(hosts, indent=2) + "\n", encoding="utf-8")
    INVENTORY.chmod(0o600)
    print(f"Generated {INVENTORY} for web={public_ip}, DB={db_private_ip}")

if __name__ == "__main__":
    main()
