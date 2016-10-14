
Dir["./config/environment.rb"].each {|file| require file }

# Require custom folders
# Dir["./app/models/**/*.rb"].each {|file| require file }


Cthulhu::Application.start
