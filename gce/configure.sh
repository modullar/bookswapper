set -e



curl -s "https://storage.googleapis.com/signals-agents/logging/google-fluentd-install.sh" | bash


cat >/etc/google-fluentd/config.d/railsapp.conf << EOF
<source>
  type tail
  format none
  path /opt/app/log/*.log
  pos_file /var/tmp/fluentd.railsapp.pos
  read_from_head true
  tag railsapp
</source>
EOF

service google-fluentd restart &


# Install dependencies from apt
apt-get update


# Install dependencies
apt-get install -y git ruby-dev build-essential libxml2-dev curl zlib1g-dev nginx mysql-client libmysqlclient-dev libsqlite3-dev imagemagick sphinxsearch

# install ruby 2.3.4 using rvm
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install 2.3.4
rvm rubygems current

# Install Nodejs 7.8
mkdir /opt/nodejs
curl https://nodejs.org/dist/v7.8.0/node-v7.8.0-linux-x64.tar.gz | tar xvzf - -C /opt/nodejs --strip-components=1
ln -s /opt/nodejs/bin/node /usr/bin/node
ln -s /opt/nodejs/bin/npm /usr/bin/npm


gem install bundler --no-ri --no-rdoc


useradd -m railsapp
chown -R railsapp:railsapp /opt/app

mkdir /opt/gem
chown -R railsapp:railsapp /opt/gem


sudo -u railsapp -H bundle install --path /opt/gem
sudo -u railsapp -H npm install

sudo -u railsapp -H RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:drop
sudo -u railsapp -H RAILS_ENV=production bundle exec rake db:create
sudo -u railsapp -H RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:structure:load
sudo -u railsapp -H RAILS_ENV=production bundle exec rake ts:index
sudo -u railsapp -H RAILS_ENV=production bundle exec rake ts:start
sudo -u railsapp -H bundle exec rake assets:precompile
sudo -u railsapp -H RAILS_ENV=production bundle exec rake secret


sudo cp /opt/app/gce/jobs.service  /lib/systemd/system/jobs.service
sudo systemctl enable jobs.service
sudo systemctl start jobs.service

sudo cp /opt/app/gce/default-nginx /etc/nginx/sites-available/default
sudo systemctl restart nginx.service

sudo mkdir /opt/app/shared
sudo mkdir /opt/app/shared/pids
sudo mkdir /opt/app/shared/sockets
sudo chown -R railsapp:railsapp /opt/app/

sudo cp /opt/app/gce/railsapp.service  /lib/systemd/system/railsapp.service
sudo systemctl enable railsapp.service
sudo systemctl start railsapp.service
