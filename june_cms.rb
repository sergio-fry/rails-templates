load_template "http://github.com/sergio-fry/rails-templates/raw/master/base.rb"

run "rm public/images/rails.png"
run "rm public/index.html"

run "echo 'New JuneCMS Application' > README"

file ".gitignore", <<-END
db/*.sqlite3
log/*.log
public/system/**/*
tags
tmp/**/*
END


# JuneCMS
git :submodule => "add ssh://git@linode1/home/git/june-cms.git vendor/plugins/june-cms"
run "git submodule update --recursive"
rake "june_cms:sync"
rake "june_cms:add_migration"
rake "db:migrate"
rake "june_cms:restore_content_unit_templates"


# Routing
generate :controller, "Welcome index"
file "config/routes.rb", <<-END
ActionController::Routing::Routes.draw do |map|
  map.root :controller => :welcome

  JuneCMS::Routes.draw(map)
end
END

# Plugins
plugin "fantom_controls", :git => "git@github.com:sergio-fry/fantom_controls.git", :submodule => true
plugin "Simple-nicEdit", :git => "git@github.com:sergio-fry/Simple-nicEdit.git", :submodule => true


# Seed
admin_password = ask("What is admin password?")
manager_password = ask("What is manager password?")

file "db/seed.rb", <<-END
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
    :username => "admin", 
    :password => "#{admin_password}", 
    :password_confirmation => "#{admin_password}", 
    :email => "sergei.udalov@gmail.com", 
    :roles => ["admin", "manager"]
  }) unless User.find_by_username("admin")

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

git :add => ".", :commit => "-m 'JuneCMS base applicaition installed'"
