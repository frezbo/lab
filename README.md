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
4. Patch a file so that vagrant-vbguest plugin installs sucessfully (If you manually installed latest vagrant, no need to patch)
	`"sudo patch --directory /usr/lib/ruby/vendor_ruby/vagrant << EOF
---
 lib/vagrant/bundler.rb | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/lib/vagrant/bundler.rb b/lib/vagrant/bundler.rb
index 5a5c185..c4a3837 100644
--- a/lib/vagrant/bundler.rb
+++ b/lib/vagrant/bundler.rb
@@ -272,7 +272,6 @@ module Vagrant

       # Reset the all specs override that Bundler does
       old_all = Gem::Specification._all
-      Gem::Specification.all = nil

       # /etc/gemrc and so on.
       old_config = nil
@@ -286,6 +285,8 @@ module Vagrant
       end
       Gem.configuration = NilGemConfig.new

+      Gem::Specification.reset
+
       # Use a silent UI so that we have no output
       Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
     return yield
EOF"`
5. Install vagrant vbguest-additions plugin: 
	`vagrant plugin install vagrant-vbguest`
6. Download centos 7 vagrant box: 
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

