# Cthulhu
Cthulhu allows you to create a message network between apps using RabbitMQ as message broker. Apps will only receive messages that match the routes defined on the routes file.

## Usage
```bash
git clone https://github.com/HealthWave/cthulhu.git
cd cthulhu && gem build cthulhu.gemspec && gem install cthulhu-*.gem && rm cthulhu-*.gem && cd ..
cthulhu new my-app com.example
cd my-app
cthulhu handler example

```

Edit my-app/config/routes.rb and add:

```ruby
route 'example.test', to: 'ExampleHandler#test'
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
cthulhu s
```

Logs are sent to STDOUT when running standalone, or to Rails.logger when running on Rails.

### Publishing a message
```ruby
# make sure 'my_action' is a method inside ExampleHandler
m = Cthulhu::Message.new(payload: {a: 1}, routing_key: 'example.test')
m.queue
```

### Receiving messages
```ruby
# app/handlers/example_handler.rb
class ExampleHandler < Cthulhu::Handler
  def test
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
  gem 'cthulhu', '~>0.5', git: 'https://github.com/HealthWave/cthulhu.git'
```
Optional initializer
```ruby
# FILE: config/initializers/cthulhu.rb
Cthulhu.configure do |config|
  # The organization. Example: 'com.example'
  config.organization = 'com.example'
  # app name.
  config.app_name = 'my-app'
  # set this to true if rails is this is running inside rails
  config.rails = true

  # Logger. You can override that per environment
  config.logger = Rails.logger

  # RabbitMQ connection info. Note some values have defaults,
  # and others you have to set yourself
  # You can override this per environment
  config.rabbit_user = ENV['RABBIT_USER']
  config.rabbit_pw = ENV['RABBIT_PW']
  config.rabbit_host = ENV['RABBIT_HOST']
  # default values
  # config.rabbit_vhost = '/'
  config.rabbit_port = ENV['RABBIT_PORT']

end

```
Publish to the network when an active record model changes:
```ruby
class Model < ActiveRecord::Base
  ...
  cthulhu_notify
  ...
end
```
