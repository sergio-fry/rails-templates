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


generate :controller, "Welcome index"

# Routing
file "config/routes.rb", <<-END
ActionController::Routing::Routes.draw do |map|
  map.root :controller => :welcome

  JuneCMS::Routes.draw(map)
end
END

# Plugins
plugin "fantom_controls", :git => "git@github.com:sergio-fry/fantom_controls.git", :submodule => true
plugin "Simple-nicEdit", :git => "git@github.com:sergio-fry/Simple-nicEdit.git", :submodule => true

