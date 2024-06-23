# Ansible

## Objective

Configure automaticly the applicative stack we need for the projet.

## Stack Ansible

- Kubernetes

## How it is work

The file inventory.ini is an inventory of all the virtual machine we have. We can separate them with roles, which gonna be use to make some specific ansible actions.

For exemple, if I need to apply a global configuration, I can use the parameters ```all``` in the hosts selecteur of ansible.
If I want to only configure the kubernetes master, I gonna create in this file the master role, and use the parameter ```master``` in the host selecteur to specify I want to apply only on the master's machine.

### Kubernetes

For the kubernetes cluster installation with ansible, I have create 3 files : 
- dependencies_ubuntu.yaml
- master.yaml
- worker.yaml

#### dependencies_ubuntu.yaml

The first file is a configuration for all the kubernetes hosts. It is use to make preparation to install the componant of kuberntes, and install it.


We start by desable SWAP, for the current system and permantly by commenting in the fstab.
```yaml
- name: disable SWAP (Kubeadm requirement)
    shell: |
        swapoff -a

- name: disable SWAP in fstab (Kubeadm requirement)
    replace:
    path: /etc/fstab
    regexp: '^([^#].*?\sswap\s+sw\s+.*)$'
    replace: '# \1'
```

We prepare some configuration for containerd, which is the system of containers kubernetes gonna use.
```yaml
- name: create an empty file for the Containerd module
    copy:
        content: ""
        dest: /etc/modules-load.d/containerd.conf
        force: no

- name: configure modules for Containerd
    blockinfile:
        path: /etc/modules-load.d/containerd.conf
        block: |
            overlay
            br_netfilter
```

We configure our linux system to make routing and permit bridge with iptables.
```yaml
- name: create an empty file for Kubernetes sysctl params
    copy:
        content: ""
        dest: /etc/sysctl.d/99-kubernetes-cri.conf
        force: no

- name: configure sysctl params for Kubernetes
  lineinfile:
    path: /etc/sysctl.d/99-kubernetes-cri.conf
    line: "{{ item }}"
  with_items:
    - 'net.bridge.bridge-nf-call-iptables  = 1'
    - 'net.ipv4.ip_forward                 = 1'
    - 'net.bridge.bridge-nf-call-ip6tables = 1'

- name: apply sysctl params without reboot
  command: sysctl --system
```

We configure the repository 
```yaml
- name: install APT Transport HTTPS
      apt:
        name: apt-transport-https
        state: present

- name: add Docker apt-key
  get_url:
    url: https://download.docker.com/linux/ubuntu/gpg
    dest: /etc/apt/keyrings/docker-apt-keyring.asc
    mode: '0644'
    force: true

- name: add Docker's APT repository
  apt_repository:
    repo: "deb [arch={{ 'amd64' if ansible_architecture == 'x86_64' else 'arm64' }} signed-by=/etc/apt/keyrings/docker-apt-keyring.asc] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present
    update_cache: yes

- name: add Kubernetes apt-key
  get_url:
    url: https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key
    dest: /etc/apt/keyrings/kubernetes-apt-keyring.asc
    mode: '0644'
    force: true

- name: add Kubernetes' APT repository
  apt_repository:
    repo: "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /"
    state: present
    update_cache: yes
```

We install containerd, configure it, and start it
```yaml
- name: install Containerd
      apt:
        name: containerd.io
        state: present

- name: create Containerd directory
  file:
    path: /etc/containerd
    state: directory

- name: add Containerd configuration
  shell: /usr/bin/containerd config default > /etc/containerd/config.toml

- name: configuring the systemd cgroup driver for Containerd
  lineinfile:
    path: /etc/containerd/config.toml
    regexp: '            SystemdCgroup = false'
    line: '            SystemdCgroup = true'

- name: enable the Containerd service and start it
  systemd:
    name: containerd
    state: restarted
    enabled: yes
    daemon-reload: yes
```

We install kubernetes packages, and enable kubelet
```yaml
- name: install Kubelet
      apt:
        name: kubelet=1.29.*
        state: present
        update_cache: true

    - name: install Kubeadm
      apt:
        name: kubeadm=1.29.*
        state: present

    - name: enable the Kubelet service, and enable it persistently
      service:
        name: kubelet
        enabled: yes
```

We configure somme linux kernel modules to make some routing
```yaml
- name: load br_netfilter kernel module
      modprobe:
        name: br_netfilter
        state: present

    - name: set bridge-nf-call-iptables
      sysctl:
        name: net.bridge.bridge-nf-call-iptables
        value: 1

    - name: set ip_forward
      sysctl:
        name: net.ipv4.ip_forward
        value: 1
```

Additionnaly, we install ```kubectl``` on our master machine. We can reboot after that, and all our machine have all the dependencies for the creation of our cluster. 


#### master.yaml

We start by creating the kubernetes cluster configuration files
```yaml
- name: create an empty file for Kubeadm configuring
      copy:
        content: ""
        dest: /etc/kubernetes/kubeadm-config.yaml
        force: no

    - name: configuring the container runtime including its cgroup driver
      blockinfile:
        path: /etc/kubernetes/kubeadm-config.yaml
        block: |
             kind: ClusterConfiguration
             apiVersion: kubeadm.k8s.io/v1beta3
             networking:
               podSubnet: "10.244.0.0/16"
             ---
             kind: KubeletConfiguration
             apiVersion: kubelet.config.k8s.io/v1beta1
             runtimeRequestTimeout: "15m"
             cgroupDriver: "systemd"
             systemReserved:
               cpu: 100m
               memory: 350M
             kubeReserved:
               cpu: 100m
               memory: 50M
             enforceNodeAllocatable:
             - pods
```

We can now initialize our cluster, and log it
```yaml
- name: initialize the cluster (this could take some time)
      shell: kubeadm init --config /etc/kubernetes/kubeadm-config.yaml >> cluster_initialized.log
      args:
        chdir: /home/admuser
        creates: cluster_initialized.log
```

After that, we need to use kubectl commands, so we gonna configure it.
```yaml
- name: create .kube directory
      become: yes
      become_user: admuser
      file:
        path: $HOME/.kube
        state: directory
        mode: 0755

    - name: copy admin.conf to user's kube config
      copy:
        src: /etc/kubernetes/admin.conf
        dest: /home/admuser/.kube/config
        remote_src: yes
        owner: admuser
```

We gonna install a POD NETWORK and Metalllb, to have service with external IP.
```yaml
- name: install Pod network
      become: yes
      become_user: admuser
      shell: kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml >> pod_network_setup.log
      args:
        chdir: $HOME
        creates: pod_network_setup.log

    - name: Copy metallb configuration on server
      copy:
        src: ./metallb/configmap.yaml
        dest: /home/admuser/configmap-metallb.yaml
        owner: admuser
        mode: 644
    
    - name: install metallb
      become: yes
      become_user: admuser
      shell: kubectl apply -f ~/configmap-metallb.yaml >> metallb_setup.log
      args:
        chdir: $HOME
        creates: metallb_setup.log
```

#### worker.yaml

To finish our cluster installation, we need to add workers to the clusters.

First, we need to create a token in the master. We gonna store it in a variable to use it later. 
```yaml
- name: get join command
      shell: kubeadm token create --print-join-command
      register: join_command_raw

    - name: set join command
      set_fact:
        join_command: "{{ join_command_raw.stdout_lines[0] }}"
```

Secondly, we add the worker to the cluster, using the token variable to connect to the master
```yaml
- name: TCP port 6443 on master is reachable from worker
      wait_for: "host={{ hostvars['master1']['ansible_default_ipv4']['address'] }} port=6443 timeout=1"

    - name: join cluster
      shell: "{{ hostvars['master1'].join_command }} >> node_joined.log"
      args:
        chdir: /home/admuser
        creates: node_joined.log
```