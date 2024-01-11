source 'https://rubygems.org'

ruby '3.2.2'

gem 'anystyle', '~> 1.3'
gem 'citeproc', '~> 1.0'
gem 'edtf', '~> 3.0'

gem 'rails', '~> 6.0'

# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use HAML for templates
gem 'haml-rails', '>= 2'

# CSS dependencies
gem 'bootstrap-sass', '~> 3.4'
gem 'font_awesome5_rails'
gem 'sass-rails', '>= 6'

# JS dependencies
gem 'angularjs-rails', '~> 1.3'
gem 'coffee-rails', '~> 5.0'
gem 'jquery-rails'
gem 'uglifier', '>= 1.3.0'

# Use the language detection normalizer
gem 'cld3'

# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Use Delayed Job for Active Job
gem 'daemons'
gem 'delayed_job_active_record'

group :development, :test do
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3', '~> 1.4'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Use Capistrano for deployment
  gem 'capistrano', require: false
  gem 'capistrano-chruby', require: false
  gem 'capistrano-rails', require: false

  gem 'listen', '>= 3.0.5', '< 3.2'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  # gem 'capybara', '>= 2.15'
  # gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  # gem 'webdrivers'
end

group :production do
  # Use PostgreSQL as the database for Active Record
  gem 'pg', '~> 1.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
