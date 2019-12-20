set :stage, :staging

server '192.168.23.5', user: 'vagrant', roles: %w{app db web}

set :ssh_options, {
  forward_agent: false,
  keys: [
    File.expand_path('../../.vagrant/machines/default/virtualbox/private_key', __dir__)
  ]
}
