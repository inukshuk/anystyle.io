#!/usr/bin/env puma

current_path = File.expand_path('../..', __FILE__)
shared_path = File.expand_path('..', __dir__)

rails_env = ENV['RAILS_ENV'] || 'development'

directory current_path
rackup "#{current_path}/config.ru"
environment rails_env

threads 1,5
workers 1

pidfile "#{shared_path}/tmp/pids/puma.pid"
state_path "#{shared_path}/tmp/pids/puma.state"

if rails_env == 'development'
  bind 'tcp://0.0.0.0:3000'
else
  bind "unix://#{shared_path}/tmp/sockets/puma.sock"
  activate_control_app "unix://#{shared_path}/tmp/sockets/ctl.sock"
end

# preload_app!

# -*- mode: ruby -*-
# vi: set ft=ruby :
