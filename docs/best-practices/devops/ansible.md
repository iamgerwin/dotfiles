# Ansible Best Practices

## Table of Contents
- [Official Documentation](#official-documentation)
- [Core Concepts](#core-concepts)
- [Project Structure Examples](#project-structure-examples)
- [Configuration Examples](#configuration-examples)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)
- [Do's and Don'ts](#dos-and-donts)
- [Additional Resources](#additional-resources)

## Official Documentation

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible User Guide](https://docs.ansible.com/ansible/latest/user_guide/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Ansible Collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)

## Core Concepts

### Ansible Components
- **Control Node**: Machine running Ansible commands
- **Managed Nodes**: Target machines managed by Ansible
- **Inventory**: List of managed nodes and their variables
- **Modules**: Units of code executed by Ansible
- **Tasks**: Units of action in Ansible
- **Playbooks**: YAML files containing plays and tasks
- **Plays**: Ordered list of tasks executed against hosts
- **Roles**: Reusable collections of tasks, variables, files, and templates

### Key Features
- **Agentless**: No software installation required on managed nodes
- **Idempotent**: Safe to run multiple times
- **Declarative**: Describe desired state, not steps
- **SSH-based**: Uses SSH for communication (Linux) or WinRM (Windows)

## Project Structure Examples

### Basic Project Structure
```
ansible-project/
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       └── all.yml
│   ├── staging/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       └── all.yml
│   └── development/
│       ├── hosts.yml
│       └── group_vars/
│           └── all.yml
├── roles/
│   ├── common/
│   ├── webserver/
│   └── database/
├── playbooks/
│   ├── site.yml
│   ├── webservers.yml
│   └── dbservers.yml
├── group_vars/
│   └── all.yml
├── host_vars/
├── collections/
│   └── requirements.yml
├── ansible.cfg
└── README.md
```

### Advanced Role Structure
```
roles/
└── webserver/
    ├── README.md
    ├── defaults/
    │   └── main.yml
    ├── files/
    │   └── nginx.conf
    ├── handlers/
    │   └── main.yml
    ├── meta/
    │   └── main.yml
    ├── tasks/
    │   ├── main.yml
    │   ├── install.yml
    │   └── configure.yml
    ├── templates/
    │   ├── nginx.conf.j2
    │   └── site.conf.j2
    ├── tests/
    │   ├── inventory
    │   └── test.yml
    └── vars/
        └── main.yml
```

## Configuration Examples

### Ansible Configuration (ansible.cfg)
```ini
[defaults]
inventory = inventories/production/hosts.yml
host_key_checking = False
timeout = 30
forks = 10
remote_user = ansible
private_key_file = ~/.ssh/ansible-key
retry_files_enabled = False
gathering = smart
fact_caching = memory
stdout_callback = yaml
bin_ansible_callbacks = True

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o ControlPath=/tmp/ansible-%h-%p-%r
pipelining = True
```

### Inventory Example (hosts.yml)
```yaml
all:
  children:
    webservers:
      hosts:
        web01:
          ansible_host: 192.168.1.10
          ansible_user: ubuntu
        web02:
          ansible_host: 192.168.1.11
          ansible_user: ubuntu
      vars:
        nginx_port: 80
        ssl_enabled: true
    
    databases:
      hosts:
        db01:
          ansible_host: 192.168.1.20
          ansible_user: ubuntu
          mysql_root_password: "{{ vault_mysql_root_password }}"
        db02:
          ansible_host: 192.168.1.21
          ansible_user: ubuntu
          mysql_root_password: "{{ vault_mysql_root_password }}"
      vars:
        mysql_port: 3306
        backup_enabled: true

  vars:
    ansible_ssh_private_key_file: ~/.ssh/ansible-key
    ansible_python_interpreter: /usr/bin/python3
```

### Main Playbook (site.yml)
```yaml
---
- name: Configure all servers
  hosts: all
  become: yes
  roles:
    - common

- name: Configure web servers
  hosts: webservers
  become: yes
  roles:
    - webserver
    - ssl-certificates
  tags:
    - webserver

- name: Configure database servers
  hosts: databases
  become: yes
  roles:
    - database
    - backup
  tags:
    - database
```

### Role Example (roles/webserver/tasks/main.yml)
```yaml
---
- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"
  tags:
    - webserver
    - config

- name: Install nginx
  package:
    name: "{{ nginx_package_name }}"
    state: present
  notify: restart nginx
  tags:
    - webserver
    - install

- name: Create nginx configuration
  template:
    src: nginx.conf.j2
    dest: "{{ nginx_conf_path }}"
    owner: root
    group: root
    mode: '0644'
    backup: yes
  notify: restart nginx
  tags:
    - webserver
    - config

- name: Create site configuration
  template:
    src: site.conf.j2
    dest: "{{ nginx_sites_path }}/{{ item.name }}.conf"
    owner: root
    group: root
    mode: '0644'
  loop: "{{ nginx_sites }}"
  notify: reload nginx
  tags:
    - webserver
    - sites

- name: Start and enable nginx
  service:
    name: nginx
    state: started
    enabled: yes
  tags:
    - webserver
    - service

- name: Check nginx is responding
  uri:
    url: "http://{{ ansible_fqdn }}"
    method: GET
    status_code: 200
  delegate_to: localhost
  become: no
  tags:
    - webserver
    - verify
```

### Variables Example (roles/webserver/defaults/main.yml)
```yaml
---
# Nginx configuration
nginx_user: www-data
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65
nginx_client_max_body_size: 1m

# Paths (OS-specific)
nginx_conf_path: /etc/nginx/nginx.conf
nginx_sites_path: /etc/nginx/sites-available
nginx_sites_enabled_path: /etc/nginx/sites-enabled

# SSL configuration
ssl_enabled: false
ssl_certificate_path: /etc/ssl/certs
ssl_private_key_path: /etc/ssl/private

# Sites configuration
nginx_sites:
  - name: default
    server_name: "{{ ansible_fqdn }}"
    root: /var/www/html
    index: index.html index.htm
    error_log: /var/log/nginx/error.log
    access_log: /var/log/nginx/access.log
```

### Handlers Example (roles/webserver/handlers/main.yml)
```yaml
---
- name: restart nginx
  service:
    name: nginx
    state: restarted
  listen: restart nginx

- name: reload nginx
  service:
    name: nginx
    state: reloaded
  listen: reload nginx

- name: validate nginx config
  command: nginx -t
  changed_when: false
  listen: restart nginx
  listen: reload nginx
```

## Best Practices

### Playbook Organization
1. **Use Roles**: Organize functionality into reusable roles
2. **Separate Environments**: Use different inventory files for each environment
3. **Group Variables**: Use group_vars and host_vars for environment-specific settings
4. **Tag Everything**: Use tags for selective execution
5. **Version Control**: Store all Ansible code in Git

### Security
1. **Ansible Vault**: Encrypt sensitive data using ansible-vault
2. **SSH Keys**: Use SSH key authentication instead of passwords
3. **Least Privilege**: Run tasks with minimum required privileges
4. **Secure Defaults**: Use secure default configurations
5. **Regular Updates**: Keep Ansible and collections updated

### Performance
1. **Parallel Execution**: Use appropriate fork settings
2. **SSH Optimization**: Use ControlMaster and pipelining
3. **Fact Caching**: Enable fact caching for large inventories
4. **Targeted Execution**: Use tags and limits for targeted runs
5. **Idempotency**: Ensure tasks are idempotent

### Testing and Validation
1. **Syntax Check**: Always validate playbook syntax
2. **Dry Run**: Use --check mode before actual execution
3. **Testing Framework**: Use Molecule for role testing
4. **CI/CD Integration**: Integrate with CI/CD pipelines
5. **Documentation**: Document roles and playbooks thoroughly

## Common Patterns

### Environment-Specific Deployments
```bash
# Deploy to specific environment
ansible-playbook -i inventories/production playbooks/site.yml

# Deploy specific roles
ansible-playbook -i inventories/staging playbooks/site.yml --tags webserver

# Limit to specific hosts
ansible-playbook -i inventories/production playbooks/site.yml --limit webservers
```

### Rolling Updates
```yaml
---
- name: Rolling update web servers
  hosts: webservers
  become: yes
  serial: 1  # Update one server at a time
  max_fail_percentage: 0
  
  pre_tasks:
    - name: Remove from load balancer
      uri:
        url: "http://{{ load_balancer }}/remove/{{ inventory_hostname }}"
        method: POST
      delegate_to: localhost
      
  roles:
    - webserver
    
  post_tasks:
    - name: Verify service is running
      uri:
        url: "http://{{ inventory_hostname }}"
        status_code: 200
      retries: 5
      delay: 10
      
    - name: Add back to load balancer
      uri:
        url: "http://{{ load_balancer }}/add/{{ inventory_hostname }}"
        method: POST
      delegate_to: localhost
```

### Conditional Task Execution
```yaml
---
- name: Install development tools
  package:
    name: "{{ dev_packages }}"
    state: present
  when: 
    - environment == "development"
    - install_dev_tools | default(false)

- name: Configure SSL
  include_tasks: ssl.yml
  when: ssl_enabled | default(false)

- name: Backup database
  command: mysqldump -u root -p{{ mysql_root_password }} --all-databases
  when: 
    - backup_enabled | default(true)
    - "'databases' in group_names"
```

### Using Ansible Vault
```bash
# Create encrypted file
ansible-vault create group_vars/production/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/production/vault.yml

# Run playbook with vault password
ansible-playbook -i inventories/production site.yml --ask-vault-pass

# Use vault password file
ansible-playbook -i inventories/production site.yml --vault-password-file .vault_pass
```

## Do's and Don'ts

### Do's
✅ **Use meaningful names** for tasks, plays, and variables
✅ **Keep playbooks simple** and use roles for complex logic
✅ **Use ansible-vault** for sensitive data
✅ **Test in development** before running in production
✅ **Use version control** for all Ansible code
✅ **Document your roles** with README files
✅ **Use handlers** for service restarts and reloads
✅ **Implement proper error handling** with failed_when and ignore_errors
✅ **Use tags** for selective execution
✅ **Follow YAML best practices** for formatting

### Don'ts
❌ **Don't hardcode passwords** or sensitive information
❌ **Don't run as root** unless absolutely necessary
❌ **Don't ignore failed tasks** without proper error handling
❌ **Don't create overly complex playbooks** in single files
❌ **Don't skip testing** before production deployment
❌ **Don't use deprecated modules** or syntax
❌ **Don't ignore idempotency** when writing tasks
❌ **Don't put secrets** in version control
❌ **Don't use shell/command** when a module exists
❌ **Don't forget to use** `--check` mode for testing

## Additional Resources

### Testing Tools
- [Ansible Molecule](https://molecule.readthedocs.io/) - Testing framework for Ansible roles
- [Ansible Lint](https://ansible-lint.readthedocs.io/) - Command-line tool for linting
- [Testinfra](https://testinfra.readthedocs.io/) - Infrastructure testing library

### IDE Support
- [Ansible VS Code Extension](https://marketplace.visualstudio.com/items?itemName=redhat.ansible)
- [Ansible IntelliJ Plugin](https://plugins.jetbrains.com/plugin/14893-ansible)
- [Vim Ansible Plugin](https://github.com/pearofducks/ansible-vim)

### Collections and Roles
- [Ansible Galaxy](https://galaxy.ansible.com/) - Community hub for roles and collections
- [Ansible Collections Index](https://docs.ansible.com/ansible/latest/collections/index.html)
- [Community General Collection](https://docs.ansible.com/ansible/latest/collections/community/general/)

### Learning Resources
- [Ansible for DevOps](https://www.ansiblefordevops.com/) - Comprehensive book
- [Ansible Workshop](https://ansible.github.io/workshops/) - Hands-on workshops
- [Red Hat Ansible Automation](https://www.redhat.com/en/technologies/management/ansible) - Enterprise solutions

### Community Resources
- [Ansible Reddit](https://www.reddit.com/r/ansible/)
- [Ansible Google Group](https://groups.google.com/g/ansible-project)
- [Ansible IRC](https://docs.ansible.com/ansible/latest/community/communication.html#irc-channels)
- [Ansible GitHub](https://github.com/ansible/ansible)

### Monitoring and Troubleshooting
- [Ansible Tower/AWX](https://github.com/ansible/awx) - Web UI and API for Ansible
- [Ansible Runner](https://ansible-runner.readthedocs.io/) - Tool for running Ansible programmatically
- [Ansible Playbook Grapher](https://github.com/haidaraM/ansible-playbook-grapher) - Visualize playbook execution