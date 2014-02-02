# HipsterPizza

HipsterPizza allows to make group orders on pizza.de. If you don’t want
to install a copy of HipsterPizza on your own server, you can use the
public instance at **[pizza.yrden.de](http://pizza.yrden.de)**.

## Status

[![Build Status](https://travis-ci.org/breunigs/hipsterpizza.png?branch=v2)](https://travis-ci.org/breunigs/hipsterpizza)
[![Coverage Status](https://coveralls.io/repos/breunigs/hipsterpizza/badge.png?branch=v2)](https://coveralls.io/r/breunigs/hipsterpizza?branch=v2)
[![Code Climate](https://codeclimate.com/github/breunigs/hipsterpizza.png?branch=v2)](https://codeclimate.com/github/breunigs/hipsterpizza?branch=v2)


## Rolling your own copy

HipsterPizza uses Rails 4 and has been tested with Ruby 2.1. Here’s how to get it running on Debian stable:
```bash
apt-get install ruby bundler git ruby-sqlite3
cd /srv
git clone -b v2 git://github.com/breunigs/hipsterpizza
cd hipsterpizza/
su www-data
```

Now, edit the `Gemfile` so that the version in the line starting with
`ruby` matches the one available on your system. In Debian’s case that
should be `1.9.3`.

Next, install the required dependencies and run HipsterPizza:
```bash
bundle --deployment --without development test
export RAILS_ENV=production
bundle exec rake assets:precompile
bundle exec rake db:migrate
bundle exec rails server -p 10002 -b localhost --daemon
```

You are almost done, now. HipsterPizza assumes you are going to run it
behind nginx, Apache or another web server. If you **don’t**, set
```ruby
# in /srv/hipsterpizza/config/environments/production.rb
config.serve_static_assets = true
```
to `true`, otherwise the assets won’t be served.

Here’s an example config for nginx:
```
upstream thin-hipsterpizza {
    server 127.0.0.1:10002;
}

server {
    listen       80;
    listen       [2001:4d88:2000:8::3001]:80 ipv6only=on deferred;
    server_name  pizza.yrden.de;
    access_log   /var/log/nginx/pizza.yrden.de.log;
    root         /srv/hipsterpizza/public;

    location ~ ^/hipster/assets/  {
        gzip_static on;
        expires max;
        add_header Cache-Control public;
    }

    location / {
        proxy_pass http://thin-hipsterpizza;
        proxy_set_header  X-Real-IP  $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header  Host $http_host;
        proxy_redirect    off;
    }
}
```
