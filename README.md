# Icinga2 Agent - Ansible Role

[![Ansible Role](https://img.shields.io/ansible/role/d/GiulioSavini/icinga2-ansible-installer)](https://galaxy.ansible.com/GiulioSavini/icinga2_agent)

Ruolo Ansible per installare **Icinga2 agent** su tutte le principali distribuzioni Linux.

## Distribuzioni supportate

| Distro | Versioni | Metodo |
|--------|----------|--------|
| Debian / Ubuntu | Tutte | apt (packages.icinga.com) |
| CentOS | 6, 7 | yum + EPEL |
| CentOS | 8 | dnf + compat-openssl10 |
| CentOS | 9, 10 | RPM da repo interno + nagios-plugins da sorgente |
| Oracle Linux | 6, 7 | yum + EPEL (come CentOS) |
| RHEL | 6, 7 | subscription-manager + yum |
| RHEL | 8 | RPM da repo interno + EPEL |
| RHEL | 9 | RPM da repo interno + EPEL |
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

## Configurazione

Prima di usare il ruolo devi configurare alcune variabili. Puoi farlo in diversi modi:
- Direttamente nel **playbook** (sotto `vars`)
- In un file **group_vars** o **host_vars**
- In un file separato incluso con `vars_files`

### 1. Host Icinga2 / NetEye (tutte le distro)

Se vuoi che il ruolo aggiunga automaticamente i tuoi server Icinga2 (master/satellite) al file `/etc/hosts` di ogni host target, devi popolare la variabile `icinga2_neteye_hosts` con IP e hostname dei tuoi server di monitoraggio:

```yaml
icinga2_neteye_hosts:
  - ip: "10.0.0.1"
    hostname: "icinga-master"
  - ip: "10.0.0.2"
    hostname: "icinga-satellite"
```

**Dove trovi queste info:** sono gli IP e gli hostname dei tuoi server Icinga2/NetEye master e satellite. Li trovi nella configurazione del tuo Icinga2 Director o nella documentazione della tua infrastruttura di monitoraggio.

Se non ti serve la gestione di `/etc/hosts` (ad esempio usi DNS), puoi disabilitarla:
```yaml
icinga2_manage_hosts_file: false
```

### 2. URL repository interno (solo RHEL 8/9 e CentOS 9/10)

Per queste distro i pacchetti Icinga2 **non sono disponibili** dai repo ufficiali. Servono RPM da un repository interno (es. NetEye Share, Artifactory, web server interno).

Devi impostare le variabili `*_base_url` con l'URL dove sono hostati i tuoi RPM di Icinga2:

| Distro | Variabile da impostare | Cosa deve contenere l'URL |
|--------|----------------------|---------------------------|
| RHEL 8 | `icinga2_rhel8_base_url` | Directory con `icinga2-*.el8.x86_64.rpm` |
| RHEL 9 | `icinga2_rhel9_base_url` | Directory con `icinga2-*.el9.x86_64.rpm` |
| CentOS 9/10 | `icinga2_centos10_base_url` | Directory con RPM Icinga2 per CentOS |

Esempio:
```yaml
icinga2_rhel8_base_url: "https://your-repo.example.com/icinga2/rhel8/RPMS/x86_64/"
icinga2_rhel9_base_url: "https://your-repo.example.com/icinga2/rhel9/RPMS/x86_64/"
icinga2_centos10_base_url: "https://your-repo.example.com/icinga2/centos10/"
```

**Dove trovi queste info:** chiedi al tuo team infrastruttura o controlla la documentazione del tuo NetEye/Icinga2 Director. L'URL e' tipicamente quello di un web server interno che espone i pacchetti RPM.

**Nota:** senza questi URL i task di download per RHEL 8/9 e CentOS 9/10 falliranno. Per le altre distro (Debian, Ubuntu, CentOS 6-8, Oracle Linux, SLES) i pacchetti vengono scaricati automaticamente dai repo ufficiali Icinga2 e non serve configurare nulla.

### 3. Versioni RPM (opzionale)

Se usi versioni diverse di Icinga2, puoi sovrascrivere:
```yaml
icinga2_rhel8_version: "2.14.2"                    # default
icinga2_rhel9_version: "2.11.9+123.g9b1c44733"     # default
icinga2_nagios_plugins_version: "2.4.11"            # default, per build da sorgente
```

## Come si usa

### Playbook minimo (Debian/Ubuntu/CentOS 6-8/SLES)

Per le distro che usano i repo ufficiali Icinga2 basta:

```yaml
---
- hosts: all
  become: true
  roles:
    - role: icinga2_agent
      vars:
        icinga2_neteye_hosts:
          - ip: "10.0.0.1"
            hostname: "icinga-master"
```

### Playbook completo (tutte le distro)

```yaml
---
- hosts: all
  become: true
  roles:
    - role: icinga2_agent
      vars:
        # Host Icinga2 da aggiungere a /etc/hosts
        icinga2_neteye_hosts:
          - ip: "10.0.0.1"
            hostname: "icinga-master"
          - ip: "10.0.0.2"
            hostname: "icinga-satellite"

        # URL repo interni (necessari solo per RHEL 8/9 e CentOS 9/10)
        icinga2_rhel8_base_url: "https://your-repo.example.com/rhel8/RPMS/x86_64/"
        icinga2_rhel9_base_url: "https://your-repo.example.com/rhel9/RPMS/x86_64/"
        icinga2_centos10_base_url: "https://your-repo.example.com/centos10/"

        # Opzionali
        icinga2_deploy_check_mem: true
        icinga2_service_enabled: true
```

### Con group_vars (consigliato per ambienti grandi)

Crea `group_vars/all.yml`:
```yaml
icinga2_neteye_hosts:
  - ip: "10.0.0.1"
    hostname: "icinga-master"
```

Crea `group_vars/rhel8.yml`:
```yaml
icinga2_rhel8_base_url: "https://your-repo.example.com/rhel8/RPMS/x86_64/"
```

Il playbook diventa semplicemente:
```yaml
---
- hosts: all
  become: true
  roles:
    - icinga2_agent
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
| `icinga2_neteye_hosts` | `[]` | Lista host Icinga2/NetEye per /etc/hosts (vedi esempio sotto) |
| `icinga2_manage_hosts_file` | `true` | Gestire /etc/hosts |
| `icinga2_deploy_check_mem` | `true` | Copiare check_mem.pl |
| `icinga2_service_enabled` | `true` | Abilitare il servizio |
| `icinga2_service_state` | `started` | Stato del servizio |
| `icinga2_plugin_path_debian` | `/usr/lib/nagios/plugins` | Path plugin Debian |
| `icinga2_plugin_path_redhat` | `/usr/lib64/nagios/plugins` | Path plugin RedHat |
| `icinga2_plugin_path_sles` | `/usr/lib64/nagios/plugins` | Path plugin SLES |
| `icinga2_rhel8_version` | `2.14.2` | Versione RPM per RHEL 8 |
| `icinga2_rhel8_base_url` | `""` | URL repo interno RPM RHEL 8 (**obbligatorio per RHEL 8**) |
| `icinga2_rhel9_version` | `2.11.9+123.g9b1c44733` | Versione RPM per RHEL 9 |
| `icinga2_rhel9_base_url` | `""` | URL repo interno RPM RHEL 9 (**obbligatorio per RHEL 9**) |
| `icinga2_centos10_base_url` | `""` | URL repo interno RPM CentOS 9/10 (**obbligatorio per CentOS 9/10**) |
| `icinga2_nagios_plugins_version` | `2.4.11` | Versione nagios-plugins (build sorgente) |

### Formato `icinga2_neteye_hosts`

```yaml
icinga2_neteye_hosts:
  - ip: "10.0.0.1"
    hostname: "icinga-master"
  - ip: "10.0.0.2"
    hostname: "icinga-satellite"
```

## Cosa fa il ruolo

1. **Aggiunge gli host Icinga2/NetEye** in `/etc/hosts` (se configurati)
2. **Installa Icinga2** con il metodo corretto per ogni distro
3. **Installa i nagios-plugins** (monitoring-plugins su Debian/SLES)
4. **Copia `check_mem.pl`** nel path corretto per la distro
5. **Fix ownership pki** su Debian/Ubuntu (workaround chiavi)
6. **Abilita e avvia** il servizio icinga2

## Note

- Per CentOS 9/10 i nagios-plugins vengono compilati da sorgente perche' non disponibili via repo
- Per RHEL 6/7 servono le subscription attive per abilitare i repo opzionali
- Per RHEL 8/9 e CentOS 9/10 serve un repository interno con gli RPM di Icinga2

## Licenza

MIT
