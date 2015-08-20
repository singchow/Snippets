require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, '128.199.214.161'
set :deploy_to, '/root/deploys'
set :repository, 'https://github.com/singchow/Snippets'
set :branch, 'master'
set :term_mode, nil
set :rvm_path, '/usr/local/rvm/scripts/rvm'

# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'log']

# Optional settings:
   set :user, 'rorsnippet'    # Username in the server to SSH to.
   set :port, '22'     # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

task :first => :environment do
  queue %[cd #{deploy_to}/current]
  queue %[bundle exec rails server -b 0.0.0.0 -d] #--pid  #{deploy_to}/tmp/server.pid
end

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

task :ping do
  queue %[ls]
end

task :update do
  queue "cd #{deploy_to}/current"
  queue "bundle install"
end

#mina update_ruby v=2.1.5
task :update_ruby do
  queue "rbenv local #{v}"
  queue "gem install bundle"
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue! %[touch "#{deploy_to}/#{shared_path}/config/secrets.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml' and 'secrets.yml'."]

  queue %[
    repo_host=`echo $repo | sed -e 's/.*@//g' -e 's/:.*//g'` &&
    repo_port=`echo $repo | grep -o ':[0-9]*' | sed -e 's/://g'` &&
    if [ -z "${repo_port}" ]; then repo_port=22; fi &&
    ssh-keyscan -p $repo_port -H $repo_host >> ~/.ssh/known_hosts
  ]
end

task :bundle_update do
  queue "cd #{deploy_to}/current"
  queue "bundle install --no-deployment"
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  to :before_hook do
    # Put things to run locally before ssh
  end
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_create'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
      queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
    end
  end
end


# assumes redis, sidekiq and rails not running
# task :start => :environment do
#   # queue %[touch redis-daemonize && echo 'daemonize yes' >> redis-daemonize && redis-server redis-daemonize]
#   queue %[cd #{deploy_to}/current]
#   # queue %[bundle exec sidekiq -d -l log/sidekiq.log]
#   queue %[rails s -e production -d]
# end

task :start => :environment do
  queue %[cd #{deploy_to}/current]
  # queue %[rails server puma -d -b 0.0.0.0 -e production --pid #{deploy_to}/tmp/server.pid]
  queue %[bundle exec puma -t 8:48 -b tcp://0.0.0.0:3000 -e production -d] #--pid  #{deploy_to}/tmp/server.pid
end

# restarts rails server, redis, and sidekiq
task :restart => :environment do
  #stop rails
  puts "- stop existing rails" if queue "kill -9 $(cat #{deploy_to}/tmp/server.pid)"
  #start rails
  puts "- change directory" if queue "cd #{deploy_to}/current"
  puts "- start new rails" if queue "rails s -e production --pid #{deploy_to}/tmp/server.pid -d"
end

task :logs do
  queue 'tail -f /var/log/nginx/error.log'
end

# task :kill_that do
#   queue "kill -9 $(cat #{deploy_to}/tmp/server.pid)"
# end



# task :console do
#   queue "cd #{deploy_to}/current"
#   queue "rails console"
# end

#mina kill pid=10353
task :kill do
  queue "kill -9 #{ENV['pid']}"
end

task :reboot do
  queue "sudo reboot"
end

task :l do
  # queue 'tail -f /var/log/nginx/error.log'
  queue "tail -f #{deploy_to}/shared/log/production.log"
  # queue "cat #{deploy_to}/shared/log/production.log"
end

task :whenever do
  queue "cd #{deploy_to}/current"
  queue "bundle exec whenever"
end

task :reboot do
  queue "sudo reboot"
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
