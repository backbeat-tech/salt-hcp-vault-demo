Vagrant.configure('2') do |config|
  config.vm.box = 'debian/buster64'

  config.vm.provider 'virtualbox' do |vb|
    vb.memory = '512'
  end

  config.vm.define 'master' do |m|
    m.vm.network 'private_network', ip: '192.168.98.2'
    m.vm.hostname = 'master.local'
    m.vm.synced_folder 'salt/', '/srv/salt', nfs: true

    m.vm.provision :salt do |salt|
      salt.install_type = 'stable'
      salt.version = '3003.1'
      salt.install_master = true
      salt.minion_config = 'config/minion.conf'
    end
  end

  config.vm.define "minion" do |m|
    m.vm.network 'private_network', ip: '192.168.98.3'
    m.vm.hostname = 'minion.local'

    m.vm.provision :salt do |salt|
      salt.install_type = 'stable'
      salt.version = '3003.1'
      salt.minion_config = 'config/minion.conf'
    end
  end
end
