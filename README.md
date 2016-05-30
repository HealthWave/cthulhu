# Cthulhu
Cthulhu allows you to create a message network between apps using RabbitMQ as message broker. For now, all messages get sent to all Cthulhu apps connected to the same broker.

## Usage
```bash
git clone https://github.com/HealthWave/cthulhu.git
cd cthulhu && gem build cthulhu.gemspec && gem install cthulhu-*.gem && rm cthulhu-*.gem && cd ..
cthulhu new my-app
cd my-app/app
cthulhu handler example

```

Edit my-app/app/config/routes.rb and add:

```ruby
route subject: 'example', to: 'ExampleHandler'
```

Change my-app/env_vars to point to your RabbitMQ.


If you are running docker, start the container by running:
```bash
my-app/boot
```

If you are not using docker:
```
cd my-app/app
bundle install
source ../env_vars bin/boot
```

Watch the logs:
```
tail -f app/logs/my-app.log
```

Publishing a message
```ruby
# make sure 'my_action' is a method inside ExampleHandler
message = {subject: 'example', action: 'my_action', payload: {id: 1, text: 'lorem ipsum'}}
Cthulhu::Message.broadcast(message)
```

Receiving messages
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

If you use rails
```
gem 'cthulhu', '~>0.2.1', git: 'https://github.com/HealthWave/cthulhu.git'

# FILE: config/initializers/cthulhu.rb
Cthulhu::Application.name = 'my-app'
# generate an unique UUID for this
Cthulhu::Application.queue_name = Cthulhu::Application.name + 'UNIQUE UUID'
Cthulhu::Application.logger = Logger.new("#{Rails.root}/log/#{Cthulhu::Application.name}.log")
Cthulhu::Application.start(block: false) # run process on a separate thread

# publish messages the same way...
```


## TODO
- Allow direct messaging
