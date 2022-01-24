# N1Loader

[![CircleCI][1]][2]
[![Gem Version][3]][4]

Are you tired of fixing [N+1 issues][7]? Does it feel unnatural to you to fix it case by case in places where you need the data?
We have a solution for you! 

[N1Loader][8] is designed to solve the issue for good!

It has many benefits:
- it can be [isolated](#isolated-loaders)
- it loads data [lazily](#lazy-loading)
- it supports [shareable loaders](#shareable-loaders) between multiple classes
- it supports [reloading](#reloading)
- it supports optimized [single object loading](#optimized-single-case)
- it supports [arguments](#arguments)
- it has an integration with [ActiveRecord][5] which makes it brilliant ([example](#activerecord))
- it has an integration with [ArLazyPreload][6] which makes it excellent ([example](#arlazypreload))

... and even more features to come! Stay tuned!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'n1_loader'
```

You can add integration with [ActiveRecord][5] by:
```ruby
gem 'n1_loader', require: 'n1_loader/active_record'
```

You can add the integration with [ActiveRecord][5] and [ArLazyPreload][6] by:
```ruby
gem 'n1_loader', require: 'n1_loader/ar_lazy_preload'
```

## Usage

```ruby
class User
  include N1Loader::Loadable

  # with inline loader
  n1_load :orders_count do |users|
    orders_per_user = Order.where(user: users).group(:user_id).count
    
    users.each { |user| fulfill(user, orders_per_user[user.id]) }
  end
end

# For single object
user = User.new
user.orders_count 

# For multiple objects without N+1
users = [User.new, User.new]
N1Loader::Preloader.new(users).preload(:orders_count)
users.map(&:orders_count)
```

### Lazy loading

```ruby
class User
  include N1Loader::Loadable

  # with inline loader
  n1_load :orders_count do |users|
    orders_per_user = Order.where(user: users).group(:user_id).count

    users.each { |user| fulfill(user, orders_per_user[user.id]) }
  end
end

user = User.new # => nothing was done for loading
user.orders_count # => first time loading

users = [User.new, User.new] # => nothing was done for loading
N1Loader::Preloader.new([users]).preload(:orders_count) # => we only initialized loader but didn't perform it yet
users.map(&:orders_count) # => loading has happen for the first time (without N+1)
```


### Shareable loaders

```ruby
class OrdersCountLoader < N1Loader::Loader
  def perform(users)
    orders_per_user = Order.where(user: users).group(:user_id).count

    users.each { |user| fulfill(user, orders_per_user[user.id]) }
  end
end

class User
  include N1Loader::Loadable

  n1_load :orders_count, OrdersCountLoader
end

class Customer
  include N1Loader::Loadable

  n1_load :orders_count, OrdersCountLoader
end

User.new.orders_count # => works
Customer.new.orders_count  # => works
```

### Reloading

```ruby
class User
  include N1Loader::Loadable

  # with inline loader
  n1_load :orders_count do |users|
    orders_per_user = Order.where(user: users).group(:user_id).count

    users.each { |user| fulfill(user, orders_per_user[user.id]) }
  end
end

user = User.new
user.orders_count # => loader is executed first time and value was cached
user.orders_count(reload: true) # => loader is executed again and a new value was cached

users = [User.new, User.new]
N1Loader::Preloader.new(users).preload(:orders_count) # => loader was initialized but not yet executed
users.map(&:orders_count) # => loader was executed first time without N+1 issue and values were cached

N1Loader::Preloader.new(users).preload(:orders_count) # => loader was initialized again but not yet executed
users.map(&:orders_count) # => new loader was executed first time without N+1 issue and new values were cached
```

### Isolated loaders

```ruby
class IsolatedLoader < N1Loader::Loader
  def perform(elements)
    elements.each { |element| fulfill(element, [element]) }
  end
end

objects = [1, 2, 3, 4]
loader = IsolatedLoader.new(objects)
objects.each do |object|
  loader.for(object) # => it has no N+1 and it doesn't require to be injected in the class
end
```

### Optimized single case

```ruby
class User
  include N1Loader::Loadable

  n1_load :orders_count do # no arguments passed to the block, so we can override both perform and single.
    def perform(users)
      orders_per_user = Order.where(user: users).group(:user_id).count

      users.each { |user| fulfill(user, orders_per_user[user.id]) }
    end
    
    # Optimized for single object loading
    def single(user)
      user.orders.count
    end
  end
end

user = User.new
user.orders_count # single will be used here

users = [User.new, User.new]
N1Loader::Preloader.new(users).preload(:orders_count)
users.map(&:orders_count) # perform will be used once without N+1
```

### Arguments

```ruby
class User
  include N1Loader::Loadable

  n1_load :orders_count do |users, type|
    orders_per_user = Order.where(type: type, user: users).group(:user_id).count

    users.each { |user| fulfill(user, orders_per_user[user.id]) }
  end
end

user = User.new
user.orders_count(:gifts) # The loader will be performed first time for this argument
user.orders_count(:sales) # The loader will be performed first time for this argument
user.orders_count(:gifts) # The cached value will be used

users = [User.new, User.new]
N1Loader::Preloader.new(users).preload(:orders_count)
users.map { |user| user.orders_count(:gifts) } # No N+1 here
```

_Note_: By default, we use `arguments.map(&:object_id)` to identify arguments but in some cases, 
you may want to override it, for example:

```ruby
class User
  include N1Loader::Loadable

  n1_load :orders_count do
    def perform(users, sale)
      orders_per_user = Order.where(sale: sale, user: users).group(:user_id).count
      
      users.each { |user| fulfill(user, orders_per_user[user.id]) }
    end

    def self.arguments_key(sale)
      sale.id
    end
  end
end

user = User.new
user.orders_count(Sale.first) # perform will be executed and value will be cached
user.orders_count(Sale.first) # the cached value will be returned
```


## Integrations

### [ActiveRecord][5]

_Note_: Rails 7 support is coming soon! Stay tuned!

```ruby
class User < ActiveRecord::Base
  include N1Loader::Loadable

  n1_load :orders_count do |users|
    orders_per_user = Order.where(user: users).group(:user_id).count

    users.each { |user| fulfill(user, orders_per_user[user.id]) }
  end
end

# For single user
user = User.first
user.orders_count 

# For many users without N+1
User.limit(5).includes(:orders_count).map(&:orders_count)

# or with explicit preloader
users = User.limit(5).to_a
N1Loader::Preloader.new(users).preload(:orders_count)

# No N+1 here
users.map(&:orders_count)
```

### [ArLazyPreload][6]

```ruby
class User < ActiveRecord::Base
  include N1Loader::Loadable

  n1_load :orders_count do |users|
    orders_per_user = Order.where(user: users).group(:user_id).count

    users.each { |user| fulfill(user, orders_per_user[user.id]) }
  end
end

# For single user
user = User.first
user.orders_count

# For many users without N+1
User.lazy_preload(:orders_count).all.map(&:orders_count)
# or 
User.preload_associations_lazily.all.map(&:orders_count)
# or 
ArLazyPreload.config.auto_preload = true
User.all.map(:orders_count)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/djezzzl/n1_loader. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the N1Loader project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Changelog

*N1Loader*'s changelog is available [here](CHANGELOG.md).

## Copyright

Copyright (c) Evgeniy Demin. See [LICENSE.txt](LICENSE.txt) for further details.

[1]: https://circleci.com/gh/djezzzl/n1_loader/tree/master.svg?style=shield
[2]: https://circleci.com/gh/djezzzl/n1_loader/tree/master
[3]: https://badge.fury.io/rb/n1_loader.svg
[4]: https://badge.fury.io/rb/n1_loader
[5]: https://github.com/rails/rails/tree/main/activerecord
[6]: https://github.com/DmitryTsepelev/ar_lazy_preload
[7]: https://stackoverflow.com/questions/97197/what-is-the-n1-selects-problem-in-orm-object-relational-mapping
[8]: https://github.com/djezzzl/n1_loader