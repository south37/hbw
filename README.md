# HBW

Simple wrapper of [Honeybadger](https://github.com/honeybadger-io/honeybadger-ruby).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hbw'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hbw

## Usage

By using `HBW.notify`, you can report error to honeybadger.io in production environment and raise error in development environment.

```ruby
HBW.notify("PaymentConfiguration", error_message, context: { company_id: self.id })
```

### Arguments

```ruby
# A. Exception only
HBW.notify(ex)

## equivalent code using `Honeybadger`
#
# if defined?(Honeybadger)
#   Honeybadger.notify(ex)
# else
#   raise ex
# end

# B. `error_class` and `error_message`
HBW.notify("PaymentConfiguration", "Empty payment period found in PaymentConfiguration#create_continuous_payments")

## equivalent code using `Honeybadger`
#
# if defined?(Honeybadger)
#   Honeybadger.notify(
#     error_class: "PaymentConfiguration",
#     error_message: "Empty payment period found in PaymentConfiguration#create_continuous_payments",
#   )
# else
#   raise "Empty payment period found in PaymentConfiguration#create_continuous_payments"
# end

# C. With other options
HBW.notify(
  "PaymentConfiguration",
  "Empty payment period found in PaymentConfiguration#create_continuous_payments",
  context: {
    payment_config_id: id,
    last_payment_id: last_payment.id
  }
)

## equivalent code using `Honeybadger`
#
# if defined?(Honeybadger)
#   Honeybadger.notify(
#     error_class: "PaymentConfiguration",
#     error_message: "Empty payment period found in PaymentConfiguration#create_continuous_payments",
#     context: {
#       payment_config_id: id,
#       last_payment_id: last_payment.id
#     }
#   )
# else
#   raise "Empty payment period found in PaymentConfiguration#create_continuous_payments"
# end
```

### `notifce_only` option

This option is default false.

```ruby
HBW.notify(ex, notice_only: true)

## equivalent code using `Honeybadger`
#
# if defined?(Honeybadger)
#   Honeybadger.notify(ex, error_message: "[Notice Only] #{ex.class}: #{ex.message}")
# else
#   raise "[Notice Only] #{ex.class}: #{ex.message}"
# end

HBW.notify("PaymentConfiguration", "Empty payment period found in PaymentConfiguration#create_continuous_payments", notice_only: true)

## equivalent code using `Honeybadger`
#
# if defined?(Honeybadger)
#   Honeybadger.notify(
#     error_class: "PaymentConfiguration",
#     error_message: "[Notice Only] Notice: Empty payment period found in PaymentConfiguration#create_continuous_payments",
#   )
# else
#   raise "[Notice Only] Notice: Empty payment period found in PaymentConfiguration#create_continuous_payments"
# end
```

### `raise_development` option

This option is default true.

```ruby
# `exception` is raised
[0] pry(main)> HBW.notify(RuntimeError.new("test error"))
RuntimeError: test error

# `exception` with specified `error_message` is raised
[1] pry(main)> HBW.notify("PaymentConfiguration", "Empty payment period found in PaymentConfiguration#create_continuous_payments")
RuntimeError: Empty payment period found in PaymentConfiguration#create_continuous_payments

# when `raise_development: false` is specified, no exception is raised
[2] pry(main)> HBW.notify(RuntimeError.new("test error"), raise_development: false)
=> nil
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/south37/hbw.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
