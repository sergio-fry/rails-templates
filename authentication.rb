load_template "https://github.com/sergio-fry/rails-templates/raw/rails2/base.rb"

name = ask("What do you want a user to be called?")
generate :nifty_authentication, name
rake "db:migrate"

git :add => ".", :commit => "-m 'adding authentication'"
