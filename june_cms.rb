require 'rubygems'
require 'active_support'

load_template "https://github.com/sergio-fry/rails-templates/raw/master/base.rb"

linode1 = "109.74.197.134"
application_name = ask("What is application name?").underscore
git_repo = "ssh://git@#{linode1}/home/git/#{application_name}.git"
manager_password = ActiveSupport::SecureRandom.base64(12)


run "git rm public/images/rails.png"
run "git rm public/index.html"
run "git rm public/javascripts/controls.js"
run "git rm public/javascripts/dragdrop.js"
run "git rm public/javascripts/effects.js"
run "git rm public/javascripts/prototype.js"

run "echo '==#{application_name.camelize} Appliction' > README"

file ".gitignore", <<-END
db/*.sqlite3
log/*.log
public/system/**/*
public/media
tags
tmp/**/*
END

# JuneCMS
git :submodule => "add ssh://git@#{linode1}/home/git/june-cms.git vendor/plugins/june-cms"
run "git submodule update --recursive"
rake "june_cms:sync"
rake "june_cms:add_migration"
rake "db:migrate"
rake "june_cms:restore_content_unit_templates"

# Layout
file "app/views/layouts/application.html.erb", <<-END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title><%= @meta_title.blank? ? @site_configuration.try(:meta_title) : @meta_title %></title>
    <meta name="keywords" content="<%= @meta_keywords.blank? ? @site_configuration.try(:meta_keywords) : @meta_keywords %>" />
    <meta name="description" content="<%= @meta_description.blank? ? @site_configuration.try(:meta_description) : @meta_description %>" />
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />

    <%= stylesheet_link_tag june_cms_stylesheets, 'application' %>
    <%= javascript_include_tag june_cms_javascripts, 'application' %>
    <%= yield(:head) %>
  </head>
  <body>
    <div id="container">
      <%= yield %>
    </div>
  </body>
</html>
END


# Routing
generate :controller, "Welcome index"
file "config/routes.rb", <<-END
ActionController::Routing::Routes.draw do |map|
  map.root :controller => :welcome

  JuneCMS::Routes.draw(map)
end
END

# Plugins
git :submodule => "add git://github.com/aaronchi/jrails.git vendor/plugins/jrails"
rake "jrails:js:scrub"
rake "jrails:js:install"

git :submodule => "add git@github.com:sergio-fry/fantom_controls.git vendor/plugins/fantom_controls"
run "git submodule update --recursive"
run "ruby script/runner vendor/plugins/fantom_controls/install.rb"

git :submodule => "add git@github.com:sergio-fry/Simple-nicEdit.git vendor/plugins/Simple-nicEdit"
run "git submodule update --recursive"
run "ruby script/runner vendor/plugins/Simple-nicEdit/install.rb"


# Seed

file "db/seeds.rb", <<-END
case RAILS_ENV
when "development"
  User.create!({
    :username => "admin",
    :password => "secret",
    :password_confirmation => "secret",
    :email => "sergei.udalov@gmail.com",
    :roles => ["admin", "manager"]
  }) unless User.find_by_username("admin")
when "production"
  User.create!({
    :username => "manager",
    :password => "#{manager_password}",
    :password_confirmation => "#{manager_password}",
    :email => "rgaifullin@gmail.com",
    :roles => ["manager"]
  }) unless User.find_by_username("manager")
end
END

rake "db:seed"

# Capistrano
run "capify ."
file "config/deploy.rb", <<-EOF
set :application, "#{application_name}"
set :repository,  "#{git_repo}"
set :server_ip,  "#{linode1}"

set :scm, :git
#set :scm_verbose, true # for old git verions
set :git_enable_submodules, 1
#set :deploy_via, :remote_cache
set :branch, "master"

# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, server_ip                          # Your HTTP server, Apache/etc
role :app, server_ip                          # This may be the same as your `Web` server
role :db, server_ip, :primary => true

set :deploy_to, "/home/railsapp/apps/\#{application}"
set :user, 'railsapp'
set :use_sudo, false
ssh_options[:keys] = ["\#{ENV['HOME']}/.ssh/id_rsa"] #Obviously needed
ssh_options[:forward_agent] = true  #Ah hah.. Success!


# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts
after "deploy", "deploy:custom_symlinks"
after "deploy", "deploy:cleanup"
after "deploy:setup", "deploy:custom_dirs"

namespace :deploy do
  task :start do
  end
  task :stop do
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "\#{try_sudo} touch \#{File.join(current_path,'tmp','restart.txt')}"
  end

  task :custom_symlinks do
    run "ln -sf \#{shared_path}/db/production.sqlite3 \#{current_path}/db/production.sqlite3"
    run "ln -sf \#{shared_path}/dragonfly_cache \#{current_path}/tmp/dragonfly"
  end

  task :custom_dirs do
    run "mkdir -p \#{shared_path}/db"
    run "mkdir -p \#{shared_path}/dragonfly_cache"
  end

  task :seed do
    run "cd \#{current_path} && rake RAILS_ENV=production db:seed"
  end

  task :update_templates do
    run "cd \#{current_path} && rake RAILS_ENV=production june_cms:restore_content_unit_templates"
  end

  task :update_unit_types do
    run "cd \#{current_path} && rake RAILS_ENV=production june_cms:update_types"
  end
end
EOF



git :add => ".", :commit => "-m 'JuneCMS base applicaition installed'"
git :remote =>"add origin #{git_repo}"
