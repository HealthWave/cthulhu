
Dir["./config/environment.rb"].each {|file| require file }

# Require custom folders
# Dir["./app/DIR/**/*.rb"].each {|file| require file }


Cthulhu::Application.start
