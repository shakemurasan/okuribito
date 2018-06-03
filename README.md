[![CircleCI](https://circleci.com/gh/muramurasan/okuribito/tree/master.svg?style=svg)](https://circleci.com/gh/muramurasan/okuribito/tree/master)
[![Code Climate](https://codeclimate.com/github/muramurasan/okuribito.png)](https://codeclimate.com/github/muramurasan/okuribito)
[![Test Coverage](https://codeclimate.com/github/muramurasan/okuribito/badges/coverage.svg)](https://codeclimate.com/github/muramurasan/okuribito/coverage)

# Okuribito

https://rubygems.org/gems/okuribito

![okuribito](okuribito_logo.png)

Okuribito is a gem to judge whether methods should be sent to the heaven :innocent:.

Okuribito monitors the method call with YAML, and exec specified code.

In other words, it can be used in order to extract the uncalled method.

Okuribito was named after a japanese movie.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'okuribito'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install okuribito

## Usage

Add `config/okuribito.yml` and edit it.

```yml
User:
  - '#feed'
Micropost:
  - '.from_users_followed_by'
Admin::Manage:
  - '.add_user'
```

By writing the following code to start the monitoring of the method.

```ruby
okuribito = Okuribito::Request.new do |method_name, obj_name, caller_info|
  # do something as you like!
end
okuribito.apply("config/okuribito.yml")
```

You can also give the option.

`once_detect`: When it detects a method call, and run only once the code that has been set.

```ruby
okuribito = Okuribito::Request.new(once_detect: true) do |method_name, obj_name, caller_info|
  # do something as you like!
end
okuribito.apply("config/okuribito.yml")
```

You can also monitor a single method with a string specification.

```ruby
okuribito = Okuribito::Request.new do |method_name, obj_name, caller_info|
  # do something as you like!
end
okuribito.apply_one("TestTarget#deprecated_method")
```

You can use the following parameters when executing arbitrary code.

* method_name
* obj_name
* caller_info (backtrace)
* class_name
* symbol (`.` or `#`)
* args

```ruby
okuribito = Okuribito::Request.new do |method_name, obj_name, caller_info, class_name, symbol, args|
  # do something as you like!
end
okuribito.apply_one("TestTarget#deprecated_method_with_args")
```

### ex: Ruby On Rails

Edit `application.rb`

```ruby
class OkuribitoSetting < Rails::Railtie
  config.after_initialize do
    okuribito = Okuribito::Request.new do |method_name, obj_name, caller_info|
      # do something as you like!
    end
    okuribito.apply("config/okuribito.yml")
  end
end
```

## The smallest example

```ruby
require "bundler/setup"
require "okuribito"

class TestTarget
  def self.deprecated_self_method
  end

  def deprecated_method
  end
end

okuribito = Okuribito::Request.new do |method_name, obj_name, caller_info|
  puts "#{obj_name} #{method_name} #{caller_info[0]}"
end
okuribito.apply("config/okuribito.yml")

TestTarget.deprecated_self_method
TestTarget.new.deprecated_method
```

Setting file:

```okuribito.yml
TestTarget:
  - ".deprecated_self_method"
  - "#deprecated_method"

```

Output:

```output
TestTarget deprecated_self_method example.rb:17:in `<main>'
#<TestTarget:0x007fd1e11ce368> deprecated_method example.rb:18:in `<main>'
```

## Callback examples

### Full stacktrace

```ruby
okuribito = Okuribito::Request.new do |method_name, obj_name, caller_info|
  puts "#############################################################"
  puts "#{obj_name} #{method_name} #{caller_info[0]}"
  puts "#############################################################"
  puts caller_info
end
okuribito.apply("config/okuribito.yml")
```

### Other ideas
- Send to Fluentd, TreasureData, Slack...

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
Copyright 2016 Yasuhiro Matsumura.
