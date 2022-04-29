# N1Loader

[![CircleCI][1]][2]
[![Gem Version][3]][4]

N1Loader is designed to provide a way for avoiding [N+1 issues][7] of any kind. 
For example, it can help with resolving N+1 for:
- database querying (most common case)
- 3rd party service calls
- complex calculations
- and many more

> [Toptal](https://www.toptal.com#snag-only-shrewd-web-development-experts) is hiring! [Join](https://www.toptal.com#snag-only-shrewd-web-development-experts) as Freelancer or [write me](mailto:lawliet.djez@gmail.com) if you want to join Core team.

## Killer feature for GraphQL API

N1Loader in combination with [ArLazyPreload][6] is a killer feature for your GraphQL API. 
Give it a try now and see incredible results instantly!

```ruby
gem 'n1_loader', require: 'n1_loader/ar_lazy_preload'
```

## Enhance [ActiveRecord][5]

Are you working with well-known Rails application? Try it out how well N1Loader fulfills missing gaps!

```ruby
gem 'n1_loader', require: 'n1_loader/active_record'
```

Are you ready to forget about N+1 once and for all? Install [ArLazyPreload][6] and see dreams come true!

```ruby
gem 'n1_loader', require: 'n1_loader/ar_lazy_preload'
```

## Standalone mode

Are you not working with [ActiveRecord][5]? N1Loader is ready to be used as standalone solution! ([full snippet](examples/core.rb))

```ruby
gem 'n1_loader'
```

### How it works?

N1Loader provides DSL that allows you to define N+1 ready loaders that can 
be injected into your objects in a way that you can avoid N+1 issues.

> _Disclaimer_: examples below are working but designed to show N1Loader potentials only. 
In real live applications, N1Loader can applied anywhere and in more [elegant way](examples/isolated_loader.rb).  

Let's look at simple example below ([full snippet](examples/active_record_integration.rb)):
```ruby
class User < ActiveRecord::Base
  has_many :payments

  n1_optimized :payments_total do |users|
    total_per_user = 
      Payment.group(:user_id)
        .where(user: users)
        .sum(:amount)
        .tap { |h| h.default = 0 }

    users.each do |user|
      total = total_per_user[user.id]
      fulfill(user, total)
    end
  end
end

class Payment < ActiveRecord::Base
  belongs_to :user

  validates :amount, presence: true
end

# A user has many payments. 
# Assuming, we want to know for group of users, what is a total of their payments, we can do the following:

# Has N+1 issue
p User.all.map { |user| user.payments.sum(&:amount) }

# Has no N+1 but we load too many data that we don't actually need
p User.all.includes(:payments).map { |user| user.payments.sum(&:amount) }

# Has no N+1 and we load only what we need
p User.all.includes(:payments_total).map { |user| user.payments_total }
```

Let's assume now, that we want to calculate the total of payments for the given period for a group of users. 
N1Loader can do that as well! ([full snippet](examples/arguments_support.rb)) 

```ruby
class User < ActiveRecord::Base
  has_many :payments

  n1_optimized :payments_total do
    argument :from
    argument :to

    def perform(users)
      total_per_user =
        Payment
          .group(:user_id)
          .where(created_at: from..to)
          .where(user: users)
          .sum(:amount)
          .tap { |h| h.default = 0 }

      users.each do |user|
        total = total_per_user[user.id]
        fulfill(user, total)
      end
    end
  end
end

class Payment < ActiveRecord::Base
  belongs_to :user

  validates :amount, presence: true
end

# Has N+1
p User.all.map { |user| user.payments.select { |payment| payment.created_at >= from && payment.created_at <= to }.sum(&:amount) }

# Has no N+1 but we load too many data that we don't need
p User.all.includes(:payments).map { |user| user.payments.select { |payment| payment.created_at >= from && payment.created_at <= to }.sum(&:amount) }

# Has no N+1 and calculation is the most efficient
p User.all.includes(:payments_total).map { |user| user.payments_total(from: from, to: to) }
```

### Features and benefits

- N1Loader doesn't use Promises which means it's easy to debug
- Doesn't require injection to objects, can be used in [isolation](examples/isolated_loader.rb)
- Loads data [lazily](examples/lazy_loading.rb)
- Loaders can be [shared](examples/shared_loader.rb) between multiple classes
- Loaded data can be [re-fetched](examples/reloading.rb)
- it supports optimized [single object loading](#optimized-single-case)
- it supports [arguments](#arguments)
- it has an integration with [ActiveRecord][5] which makes it brilliant ([example](#activerecord))
- it has an integration with [ArLazyPreload][6] which makes it excellent ([example](#arlazypreload))

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

  n1_optimized :orders_count, OrdersCountLoader
end

class Customer
  include N1Loader::Loadable

  n1_optimized :orders_count, OrdersCountLoader
end

User.new.orders_count # => works
Customer.new.orders_count  # => works
```

### Reloading

```ruby
class User
  include N1Loader::Loadable

  # with inline loader
  n1_optimized :orders_count do |users|
    orders_per_user = Order.where(user: users).group(:user_id).count

    users.each { |user| fulfill(user, orders_per_user[user.id]) }
  end
end

user = User.new
user.orders_count # => loader is executed first time and value was cached
user.orders_count(reload: true) # => loader is executed again and a new value was cached
# or
user.n1_clear_cache
user.orders_count

users = [User.new, User.new]
N1Loader::Preloader.new(users).preload(:orders_count) # => loader was initialized but not yet executed
users.map(&:orders_count) # => loader was executed first time without N+1 issue and values were cached

N1Loader::Preloader.new(users).preload(:orders_count) # => loader was initialized again but not yet executed
users.map(&:orders_count) # => new loader was executed first time without N+1 issue and new values were cached
```

### Optimized single case

```ruby
class User
  include N1Loader::Loadable

  n1_optimized :orders_count do # no arguments passed to the block, so we can override both perform and single.
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

  n1_optimized :orders_count do 
    argument :type 
    
    def perform(users)
      orders_per_user = Order.where(type: type, user: users).group(:user_id).count
      
      users.each { |user| fulfill(user, orders_per_user[user.id]) }
    end
  end
end

user = User.new
user.orders_count(type: :gifts) # The loader will be performed first time for this argument
user.orders_count(type: :sales) # The loader will be performed first time for this argument
user.orders_count(type: :gifts) # The cached value will be used

users = [User.new, User.new]
N1Loader::Preloader.new(users).preload(:orders_count)
users.map { |user| user.orders_count(type: :gifts) } # No N+1 here
```

_Note_: By default, we use `arguments.map(&:object_id)` to identify arguments but in some cases, 
you may want to override it, for example:

```ruby
class User
  include N1Loader::Loadable

  n1_optimized :orders_count do
    argument :sale, optional: true, default: -> { Sale.last }
    
    cache_key { sale.id }
    
    def perform(users)
      orders_per_user = Order.where(sale: sale, user: users).group(:user_id).count
      
      users.each { |user| fulfill(user, orders_per_user[user.id]) }
    end
  end
end

user = User.new
user.orders_count(sale: Sale.first) # perform will be executed and value will be cached
user.orders_count(sale: Sale.first) # the cached value will be returned
```


## Integrations

### [ActiveRecord][5]

_Note_: Rails 7 support is coming soon! Stay tuned!

```ruby
class User < ActiveRecord::Base
  include N1Loader::Loadable

  n1_optimized :orders_count do |users|
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

  n1_optimized :orders_count do |users|
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