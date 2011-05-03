git :init

run "echo 'TODO add readme content' > README"
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run "cp config/database.yml config/example_database.yml"

file ".gitignore", <<-END
.bundle
config/database.yml
db/*.sqlite3
log/*.log
tmp/
END

git :add => ".", :commit => "-m 'initial commit'"
