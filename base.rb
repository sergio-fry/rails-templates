git :init

run "echo 'TODO add readme content' > README"
run "touch tmp/.gitignore log/.gitignore"

git :add => ".", :commit => "-m 'initial commit'"
