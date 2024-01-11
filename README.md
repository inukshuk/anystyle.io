# AnyStyle.io
This is the [anystyle.io](https://anystyle.io) web app, a fast, smart, and
interactive parser for academic references and bibliographies.

See [anystyle](https://github.com/inukshuk/anystyle) for more details.

## Roadmap / Wishlist

* Upload PDFs for reference extraction
* Re-format parsed references with any CSL style
* Improve integration with Zotero

## Development Quickstart
    $ ruby -v
    # ruby 3.2.2

    # Install RubyGems
    $ bundle install

    # Set your credentials and generate config/master.key
    $ ./bin/rails credentials:edit

    # Create dev database
    $ ./bin/rake db:create
    $ ./bin/rake db:schema:load

    # Make sure tests are green!
    $ ./bin/rake test

    # Start dev server and (optionally) worker
    $ ./bin/rails s
    $ ./bin/rake jobs:work

## Using the Staging Box
    # You may want to edit Vagrantfile first!
    $ vagrant up

    # Set your credentials and generate config/master.key (if you haven't yet)
    $ ./bin/rails credentials:edit

    # Initial deployment...
    $ bundle exec cap staging deploy:check
    $ bundle exec cap staging deploy

    # Enable the anystyle services in the staging box
    $ vagrant ssh
    v sudo systemctl enable --now anystyle.service
    v sudo systemctl enable --now anystyle-worker.service

    # Open https://192.168.23.5 in your Browser!

## Roll Your Own
You can deploy the AnyStyle.io web-app to your own server! The
[provisoning scripts](https://github.com/inukshuk/anystyle.io/blob/master/Vagrantfile#L25)
and the sample server config files illustrate all the necessary setup.

## License
Copyright 2013-2020 Sylvester Keil and Johannes Krtek.
All rights reserved.

AnyStyle.io is distributed under the GNU Affero General Public License.
See LICENSE for details.
