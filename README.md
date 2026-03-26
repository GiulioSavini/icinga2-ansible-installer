# Icinga2 Agent - Ansible Role

[![Ansible Role](https://img.shields.io/ansible/role/d/GiulioSavini/icinga2-ansible-installer)](https://galaxy.ansible.com/GiulioSavini/icinga2_agent)

Ruolo Ansible per installare **Icinga2 agent** su tutte le principali distribuzioni Linux.

## Distribuzioni supportate

| Distro | Versioni | Metodo |
|--------|----------|--------|
| Debian / Ubuntu | Tutte | apt (packages.icinga.com) |
| CentOS | 6, 7 | yum + EPEL |
| CentOS | 8 | dnf + compat-openssl10 |
| CentOS | 9, 10 | RPM da NetEye Share + nagios-plugins da sorgente |
| Oracle Linux | 6, 7 | yum + EPEL (come CentOS) |
| RHEL | 6, 7 | subscription-manager + yum |
| RHEL | 8 | RPM da NetEye Share + EPEL |
| RHEL | 9 | RPM da NetEye Share + EPEL |
| SLES | 15 | zypper (packages.icinga.com) |

## Struttura del ruolo

```
icinga2-ansible-installer/
├── defaults/main.yml          # Variabili default
├── files/check_mem.pl         # Plugin custom per check memoria
├── handlers/main.yml          # Handler restart/enable icinga2
├── meta/main.yml              # Metadata Ansible Galaxy
├── tasks/
│   ├── main.yml               # Smista per distro
│   ├── hosts.yml              # Configurazione /etc/hosts
│   ├── debian.yml             # Debian / Ubuntu
│   ├── redhat-6-7.yml         # CentOS / Oracle Linux 6-7
│   ├── centos-8.yml           # CentOS 8
│   ├── centos-9-10.yml        # CentOS 9-10
│   ├── rhel-6-7.yml           # RHEL 6-7
│   ├── rhel-8.yml             # RHEL 8
│   ├── rhel-9.yml             # RHEL 9
│   ├── sles.yml               # SLES 15
│   └── check_mem.yml          # Deploy plugin check_mem.pl
└── README.md
```

## Prerequisiti

- **Ansible** >= 2.9
- **Accesso SSH** verso gli host target
- **Privilegi sudo/root** sugli host target
- Per SLES: collection `community.general`
  ```bash
  ansible-galaxy collection install community.general
  ```

## Installazione

### Da Ansible Galaxy

```bash
ansible-galaxy install giuliosavini.icinga2_agent
```

### Da GitHub

```bash
ansible-galaxy install git+https://github.com/GiulioSavini/icinga2-ansible-installer.git,main
```

### Manuale

```bash
git clone https://github.com/GiulioSavini/icinga2-ansible-installer.git
# Copia o linka nella directory dei ruoli:
#   ~/.ansible/roles/icinga2_agent
#   oppure ./roles/icinga2_agent
```

## Come si usa

### Playbook minimo

```yaml
---
- hosts: all
  become: yes
  roles:
    - icinga2_agent
```

### Con variabili custom

```yaml
---
- hosts: all
  become: yes
  roles:
    - role: icinga2_agent
      vars:
        icinga2_neteye_hosts:
          - ip: "10.0.0.1"
            hostname: "neteye-master"
          - ip: "10.0.0.2"
            hostname: "neteye-satellite"
        icinga2_deploy_check_mem: true
        icinga2_service_enabled: true
```

### Lancia il playbook

```bash
# Con chiave SSH
ansible-playbook -i inventory.ini site.yml

# Con password SSH
ansible-playbook -i inventory.ini site.yml --ask-pass --ask-become-pass

# Solo su un host specifico
ansible-playbook -i inventory.ini site.yml --limit server1

# Dry-run
ansible-playbook -i inventory.ini site.yml --check
```

### Verifica l'installazione

```bash
ansible -i inventory.ini all -m shell -a "icinga2 --version"
ansible -i inventory.ini all -m shell -a "systemctl status icinga2 || service icinga2 status"
```

## Variabili

Tutte le variabili con i valori default si trovano in [`defaults/main.yml`](defaults/main.yml).

| Variabile | Default | Descrizione |
|-----------|---------|-------------|
| `icinga2_neteye_hosts` | vedi defaults | Lista host NetEye per /etc/hosts |
| `icinga2_manage_hosts_file` | `true` | Gestire /etc/hosts |
| `icinga2_deploy_check_mem` | `true` | Copiare check_mem.pl |
| `icinga2_service_enabled` | `true` | Abilitare il servizio |
| `icinga2_service_state` | `started` | Stato del servizio |
| `icinga2_plugin_path_debian` | `/usr/lib/nagios/plugins` | Path plugin Debian |
| `icinga2_plugin_path_redhat` | `/usr/lib64/nagios/plugins` | Path plugin RedHat |
| `icinga2_plugin_path_sles` | `/usr/lib64/nagios/plugins` | Path plugin SLES |
| `icinga2_rhel8_version` | `2.14.2` | Versione RPM per RHEL 8 |
| `icinga2_rhel9_version` | `2.11.9+123.g9b1c44733` | Versione RPM per RHEL 9 |
| `icinga2_nagios_plugins_version` | `2.4.11` | Versione nagios-plugins (build sorgente) |

## Cosa fa il ruolo

1. **Aggiunge gli host NetEye** in `/etc/hosts`
2. **Installa Icinga2** con il metodo corretto per ogni distro
3. **Installa i nagios-plugins** (monitoring-plugins su Debian/SLES)
4. **Copia `check_mem.pl`** nel path corretto per la distro
5. **Fix ownership pki** su Debian/Ubuntu (workaround chiavi)
6. **Abilita e avvia** il servizio icinga2

## Note

- `ignore_errors: yes` su alcuni task dove i pacchetti potrebbero non essere disponibili
- Per CentOS 9/10 i nagios-plugins vengono compilati da sorgente
- Per RHEL 6/7 servono le subscription attive
- Gli RPM per RHEL 8/9 e CentOS 9/10 vengono scaricati dal NetEye Share di Irideos

## Licenza

MIT
