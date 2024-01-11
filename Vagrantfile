# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = 'debian/buster64'

  config.vm.network 'private_network', ip: '192.168.23.5'
  #config.vm.network 'forwarded_port', guest: 5432, host: 2345

  config.vm.synced_folder '.', '/vagrant',
    type: 'nfs',
    mount_options: ['rw', 'vers=3', 'tcp'],
    linux__nfs_options: ['rw','no_subtree_check','all_squash','async']

  config.ssh.forward_agent = true

  config.vm.provider 'virtualbox' do |vbox|
    vbox.memory = 1024
  end

  config.vm.provider 'libvirt' do |libvirt|
    libvirt.memory = 1024
  end

  config.vm.provision 'bootstrap', type: 'shell', inline: <<~EOS
      echo "deb http://ftp.at.debian.org/debian buster main contrib non-free" \
        | tee /etc/apt/sources.list
      sed -i -E 's/^# (en_US.UTF-8)/\\1/' /etc/locale.gen
      locale-gen
      update-locale LANG=en_US.UTF-8
      . /etc/default/locale
    EOS

  config.vm.provision 'update', type: 'shell',
    env: { DEBIAN_FRONTEND: 'noninteractive' },
    inline: <<~EOS
      apt-get update
      apt-get dist-upgrade -yq
      apt-get install -yq vim tmux git curl nginx ssl-cert \
        postgresql postgresql-server-dev-all nodejs \
        build-essential bison zlib1g-dev libyaml-dev libssl-dev \
        libgdbm-dev libreadline-dev libffi-dev libncurses5-dev
    EOS

  config.vm.provision 'ruby', type: 'shell', inline: <<~EOS
    if ! which ruby-install; then
      curl -Ls https://github.com/postmodern/ruby-install/archive/v0.9.3.tar.gz \
        | tar xz -C /tmp
      cd /tmp/ruby-install-0.9.3
      make install
    fi

    if ! test -d /usr/local/share/chruby; then
      curl -Ls https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz \
        | tar xz -C /tmp
      cd /tmp/chruby-0.3.9
      make install
      echo "if [ -n \\"\\$BASH_VERSION\\" ]; then . /usr/local/share/chruby/chruby.sh; fi" \
        | tee /etc/profile.d/chruby.sh
      echo "chruby" $(cat /vagrant/.ruby-version) \
        | tee -a /home/vagrant/.bashrc
    fi

    ruby-install -c --no-reinstall $(cat /vagrant/.ruby-version)
    . /usr/local/share/chruby/chruby.sh
    chruby $(cat /vagrant/.ruby-version)
    gem update --system
    gem install bundler --force
    ruby -v
    gem -v
    bundler -v
  EOS

  config.vm.provision 'db', type: 'shell', inline: <<~EOS
    sudo -iu postgres psql -c \
      "CREATE ROLE ghost WITH SUPERUSER CREATEDB LOGIN ENCRYPTED PASSWORD 'Zg:2Luy~Q9+MOo=H'"
    sudo -iu postgres createdb -O ghost anystyle
    echo "listen_addresses = '*'" >> /etc/postgresql/11/main/postgresql.conf
    echo "host all ghost 192.168.23.1/8 md5 " >> /etc/postgresql/11/main/pg_hba.conf
    systemctl restart postgresql.service
  EOS

  config.vm.provision 'stage', type: 'shell', inline: <<~EOS
    gpasswd -a vagrant www-data

    install -d -m 0755 -o vagrant -g www-data \
      /var/www/anystyle \
      /var/www/anystyle/releases \
      /var/www/anystyle/shared \
      /var/www/anystyle/shared/backups \
      /var/www/anystyle/shared/config

    install -T -m 0600 -o vagrant -g www-data \
      /vagrant/config/master.key \
      /var/www/anystyle/shared/config/master.key

    echo "Generating staging certificates, this may take awhile..."
    openssl dhparam -out /etc/nginx/dhparam.pem 2048 &> /dev/null
    openssl genrsa -out /etc/nginx/cert.key &> /dev/null
    openssl req -new -x509 -days 3650 -batch \
      -out /etc/nginx/cert.pem \
      -key /etc/nginx/cert.key &> /dev/null

    install -T -m 0644 -o root -g root \
      /vagrant/config/nginx.conf.example \
      /etc/nginx/sites-available/anystyle

    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/anystyle /etc/nginx/sites-enabled

    nginx -t
    systemctl reload nginx.service

    install -T -m 0644 -o root -g root \
      /vagrant/config/puma.service.example \
      /etc/systemd/system/anystyle.service
    install -T -m 0644 -o root -g root \
      /vagrant/config/worker.service.example \
      /etc/systemd/system/anystyle-worker.service

    systemctl daemon-reload
    #systemctl enable anystyle.service
    #systemctl enable anystyle-worker.service
  EOS
end
