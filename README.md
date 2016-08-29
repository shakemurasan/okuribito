# Okuribito

![okuribito](okuribito_logo.png)

Okuribito is a gem to judge whether methods should be sent to the heaven :innocent:.
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

```yml:config/okuribito.yml
User:
  - '#feed'
Micropost:
  - '.from_users_followed_by'
```

Edit `application.rb`

```ruby:application.rb
class OkuribitoSetting < Rails::Railtie
  config.after_initialize do
    okuribito = Okuribito::OkuribitoPatch.new(
      {
        console: "back_trace",
        slack: "https://hooks.slack.com/services/xxxxxxxxx/xxxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxx",
        logging: "log/okuribito/method_called.log",
        first_prepended: "log/okuribito/first_prepended.log"
      }
    )
    okuribito.apply("okuribito.yml")
  end
end
```

### console
Setting for console outout.
- `plain` is the simplest 1 line log.
- `back_trace` shows back trace in detail.

### slack
Setting for slack notification.

### logging
Setting for logging.

### first_prepended
Setting for logging to save when you started to monitor.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/okuribito. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

