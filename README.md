# Icinga2 Ansible Installer

Playbook Ansible per installare **Icinga2 agent** su tutte le principali distribuzioni Linux.

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

## Struttura del progetto

```
.
├── icinga2_install.yml   # Playbook principale
├── inventory.ini         # Inventario host (da personalizzare)
├── check_mem.pl          # Plugin custom per check memoria
└── README.md
```

## Prerequisiti

- **Ansible** >= 2.9 installato sulla macchina di controllo
- **Accesso SSH** (con chiave o password) verso tutti gli host target
- **Privilegi sudo/root** sugli host target
- Per SLES: collection `community.general` installata
  ```bash
  ansible-galaxy collection install community.general
  ```

## Come si usa

### 1. Clona la repo

```bash
git clone https://github.com/GiulioSavini/icinga2-ansible-installer.git
cd icinga2-ansible-installer
```

### 2. Configura l'inventario

Modifica `inventory.ini` con i tuoi host:

```ini
[linux_servers]
server1  ansible_host=192.168.1.10  ansible_user=root
server2  ansible_host=192.168.1.11  ansible_user=admin  ansible_become_pass=password
```

Puoi raggruppare per distro se preferisci, ma non serve: il playbook rileva automaticamente la distro con i facts di Ansible.

### 3. Lancia il playbook

```bash
# Con chiave SSH
ansible-playbook -i inventory.ini icinga2_install.yml

# Con password SSH
ansible-playbook -i inventory.ini icinga2_install.yml --ask-pass --ask-become-pass

# Solo su un gruppo o host specifico
ansible-playbook -i inventory.ini icinga2_install.yml --limit server1

# Dry-run (controlla senza applicare)
ansible-playbook -i inventory.ini icinga2_install.yml --check
```

### 4. Verifica l'installazione

```bash
# Controlla che icinga2 sia installato
ansible -i inventory.ini all -m shell -a "icinga2 --version"

# Controlla che il servizio sia attivo
ansible -i inventory.ini all -m shell -a "systemctl status icinga2 || service icinga2 status"
```

## Cosa fa il playbook

1. **Aggiunge gli host NetEye** in `/etc/hosts` (neteye-sat-udpdp-03 e neteye-sat-udpdp-04)
2. **Installa Icinga2** con il metodo corretto per ogni distro
3. **Installa i nagios-plugins** (monitoring-plugins su Debian/SLES)
4. **Copia `check_mem.pl`** nel path corretto:
   - Debian/Ubuntu: `/usr/lib/nagios/plugins/`
   - RedHat/SLES: `/usr/lib64/nagios/plugins/`
5. **Fix ownership pki** su Debian/Ubuntu (workaround per le chiavi)

## Note

- Il playbook usa `ignore_errors: yes` su alcuni task dove i pacchetti potrebbero non essere disponibili su tutte le minor version
- Per CentOS 9/10 i nagios-plugins vengono compilati da sorgente perche' non disponibili via repo
- Per RHEL 6/7 servono le subscription attive per abilitare i repo opzionali
- Gli RPM per RHEL 8/9 e CentOS 9/10 vengono scaricati dal NetEye Share di Irideos

## Personalizzazione

- **Host NetEye**: modifica gli IP nel primo task del playbook
- **Versioni RPM**: aggiorna i nomi file RPM nei task di download se disponibili versioni piu' recenti
- **Plugin aggiuntivi**: aggiungi altri task `copy` per distribuire plugin custom
