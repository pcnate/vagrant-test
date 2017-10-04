
Vagrant.configure("2") do |config|

  config.vm.box = "debian/stretch64"

  config.vm.hostname = "node-dev"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.synced_folder "src/", "/var/www/public", :mount_options => ["dmode=777", "fmode=666"]
  config.vm.provision "shell", path: "install.sh", privileged: false

end
