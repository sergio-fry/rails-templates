load_template "http://github.com/sergio-fry/rails-templates/raw/master/base.rb"

run "rm public/images/rails.png"
run "rm public/index.html"
run "rm public/javascripts/controls.js"
run "rm public/javascripts/dragdrop.js"
run "rm public/javascripts/effect.js"
run "rm public/javascripts/prototype.js"

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

# Layout
file "app/views/layouts/application.html.erb", <<-END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title><%= h(yield(:title) || "Untitled") %></title>
    <%= stylesheet_link_tag jun_cms_stylesheets, 'application' %>
    <%= javascript_include_tag jun_cms_javascripts, 'application' %>
    <%= yield(:head) %>
  </head>
  <body>
    <div id="container">
      <%- flash.each do |name, msg| -%>
        <%= content_tag :div, msg, :id => "flash_\#{name}" %>
      <%- end -%>
      
      <%- if show_title? -%>
        <h1><%=h yield(:title) %></h1>
      <%- end -%>
      
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
plugin "fantom_controls", :git => "git@github.com:sergio-fry/fantom_controls.git", :submodule => true
plugin "Simple-nicEdit", :git => "git@github.com:sergio-fry/Simple-nicEdit.git", :submodule => true


# Seed
admin_password = ask("What is admin password?")
manager_password = ask("What is manager password?")

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
