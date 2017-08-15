Vagrant.configure(2) do |config|
  config.vm.box = 'bento/ubuntu-16.04'
  config.vm.hostname = 'postgresql-db'
  config.vm.provision :shell, path: 'provision.sh'
  config.vm.synced_folder ".", "/vagrant"

  # guest - is a VM
  config.vm.network :forwarded_port,
                    guest: 5432,
                    host: 54321,
                    auto_correct: true
end
