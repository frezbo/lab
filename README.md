# RHEL7.2 lab script

Vagrant files for RHEL7.2 exam preparation.

## Installation

### Ubuntu 16.04.1 LTS

#### Provider: virtualbox

1. Update repos: 
	`sudo apt update`
2. Install vagrant: 
	`sudo apt -y install vagrant`
3. Install virtualbox: 
	`sudo apt -y install virtualbox`
4. Patch a file if vagrant version is 1.8.1 (If you manually installed latest vagrant, no need to patch) link: http://stackoverflow.com/questions/36811863/cant-install-vagrant-plugins-in-ubuntu-16-04/36991648
	`vagrant box add centos/7` If asked for provider select virtualbox.
7. Clone this and run `vagrant up` inside lab/virtualbox

###CentOS 7.2/Fedora 24

#### Provider: libvirt

1. Update: `sudo yum update`
2. Install dependencies and vagrant: 
	`sudo yum -y install vagrant redhat-rpm-config vagrant-libvirt vagrant-libvirt-doc libvirt-devel libxslt-devel libxml2-devel virt-manager`
3. Install required vagrant plugins: 
	`vagrant plugin install vagrant-libvirt`
	`vagrant plugin install fog`
	`vagrant plugin install sahara`
4. Download centos 7 vagrant box: 
        `vagrant box add centos/7` If asked for provider select libvirt.
5. Clone this and run `vagrant up` inside lab/libvirt

NB: If using fedora replace yum by dnf
NB: run `vagrant up --no-parallel` to prevent bringing up all VM's together

