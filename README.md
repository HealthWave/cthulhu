# Cthulhu
Cthulhu allows you to create a message network between apps using RabbitMQ as message broker. For now, all messages get sent to all Cthulhu apps connected to the same broker.

## Usage
```bash
git clone https://github.com/HealthWave/cthulhu.git
cd cthulhu && gem build cthulhu.gemspec && gem install cthulhu-*.gem && rm cthulhu-*.gem && cd ..
cthulhu new my-app
cd my-app
cthulhu handler example

```

Edit my-app/config/routes.rb and add:

```ruby
route subject: 'example', to: 'ExampleHandler'
```

The app requires 5 env vars:
```
CTHULHU_ENV=development
RABBIT_HOST=rabbitmq
RABBIT_PORT=5672
RABBIT_USER=user
RABBIT_PW=password
```

To run the app:
```
cd my-app
bundle install
cthulhu server
```

Watch the logs:
```
tail -f log/my-app.log
```

### Publishing a message
```ruby
# make sure 'my_action' is a method inside ExampleHandler
message = {subject: 'example', action: 'my_action', payload: {id: 1, text: 'lorem ipsum'}}
Cthulhu.publish(message)
```

### Receiving messages
```ruby
# app/handlers/example_handler.rb
class ExampleHandler < Cthulhu::Handler
  def my_action
    puts message
    puts properties
    puts headers
    # do something awesome
    ack! # or reject! or ignore!
  end
end
```

### If you use rails

Adding this to your `Gemfile`
```ruby
  gem 'cthulhu', '~>0.3.0', git: 'https://github.com/HealthWave/cthulhu.git'
```
Optional initializer
```ruby
# FILE: config/initializers/cthulhu.rb
Cthulhu::Application.logger = Rails.logger
```
Publish to the network when an active record model changes:
```ruby
class Model < ActiveRecord::Base
  ...
  cthulhu_notify
  ...
end
```

##RPC calls

Cthulhu can do unsafe RPC calls too. Just edit config/application.rb on your cthulhu app, or create an initializer for rails with:
```ruby
# The name of the apps must match the cthulhu app name, or Rails.application.class.parent_name
RPC_APPS = ["MyMonolith1", "MyMonolith2"]
```


##Running on Rails
Create the file config/initializers/cthulhu.rb
```
Cthulhu.configure do
  rails = true
  organization = 'com.example'
  app_name = 'myApp'
  fqan = "#{organization}.#{app_name}"
  parent_inbox_exchange = fqan
  inbox_exchange = "#{parent_inbox_exchange}.#{inbox}"
end
```
