lock '3.11.2'

set :application, 'anystyle'
set :repo_url, 'https://github.com/inukshuk/anystyle.io.git'

set :deploy_to, '/var/www/anystyle'

set :rails_env, 'production'
set :chruby_ruby, 'ruby-2.6.4'

append :linked_files,
#  'config/database.yml',
#  'config/puma.rb'
  'config/master.key'

append :linked_dirs,
  '.bundle',
  'log',
  'storage',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets'
