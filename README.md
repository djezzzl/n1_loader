# N1Loader

[![Gem Version][3]][4]
[![][11]][12]
[![][13]][14]
[![][9]][10]

N1Loader is designed to provide a simple way for avoiding [N+1 issues][7] of any kind. 
For example, it can help with resolving N+1 for:
- database querying (most common case)
- 3rd party service calls
- complex calculations
- and many more

> If the project helps you or your organization, I would be very grateful if you [contribute][15] or [donate][10].  
> Your support is an incredible motivation and the biggest reward for my hard work.

___Support:___ ActiveRecord 5, 6, 7, and 8.

Follow me and stay tuned for the updates:
- [LinkedIn](https://www.linkedin.com/in/evgeniydemin/)
- [Medium](https://evgeniydemin.medium.com/)
- [Twitter](https://twitter.com/EvgeniyDemin/)
- [GitHub](https://github.com/djezzzl)

## Killer feature for GraphQL API

N1Loader in combination with [ArLazyPreload][6] is a killer feature for your GraphQL API. 
Give it a try now and see incredible results instantly! Check out the [example](examples/graphql.rb) and start benefiting from it in your projects!

```ruby
gem 'n1_loader', require: 'n1_loader/ar_lazy_preload'
```

## Enhance [ActiveRecord][5]

Are you working with well-known Rails application? Try it out and see how well N1Loader fulfills missing gaps when you can't define ActiveRecord associations!
Check out the detailed [guide](guides/enhanced-activerecord.md) with examples or its [short version](examples/active_record_integration.rb).

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

## How to use it?

N1Loader provides DSL that allows you to define N+1 ready loaders that can 
be injected into your objects in a way that you can avoid N+1 issues.

> _Disclaimer_: examples below are working but designed to show N1Loader potentials only.
In real live applications, N1Loader can be applied anywhere and in more [elegant way](examples/isolated_loader.rb).  

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

## Features and benefits

- N1Loader doesn't use Promises which means it's easy to debug
- Doesn't require injection to objects, can be used in [isolation](examples/isolated_loader.rb)
- Loads data [lazily](examples/lazy_loading.rb)
- Loaders can be [shared](examples/shared_loader.rb) between multiple classes
- Loaded data can be [re-fetched](examples/reloading.rb)
- Loader can be optimized for [single cases](examples/single_case.rb)
- Loader support [arguments](examples/arguments_support.rb)
- Has [integration](examples/active_record_integration.rb) with [ActiveRecord][5] which makes it brilliant
- Has [integration](examples/ar_lazy_integration.rb) with [ArLazyPreload][6] which makes it excellent

### Feature killer for [ArLazyPreload][6] integration with isolated loaders

In [version 1.6.0](CHANGELOG.md#160---20221019) isolated loaders were integrated with [ArLazyPreload][6] context.
This means, it isn't required to inject `N1Loader` into your [ActiveRecord][5] models to avoid N+1 issues out of the box.
It is especially great as many engineers are trying to avoid extra coupling between their models/services when it's possible.
And this feature was designed exactly for this without losing an out of a box solution for N+1.

Without further ado, please have a look at the [example](examples/ar_lazy_integration_with_isolated_loader.rb).

_Spoiler:_ as soon as you have your loader defined, it will be as simple as `Loader.for(element)` to get your data efficiently and without N+1.

## Funding

### Open Collective Backers

You're an individual who wants to support the project with a monthly donation. Your logo will be available on the Github page. [[Become a backer](https://opencollective.com/n1_loader#backer)]

<a href="https://opencollective.com/n1_loader/backer/0/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/0/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/1/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/1/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/2/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/2/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/3/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/3/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/4/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/4/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/5/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/5/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/6/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/6/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/7/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/7/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/8/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/8/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/9/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/9/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/10/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/10/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/11/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/11/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/12/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/12/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/13/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/13/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/14/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/14/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/15/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/15/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/16/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/16/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/17/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/17/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/18/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/18/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/19/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/19/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/20/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/20/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/21/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/21/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/22/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/22/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/23/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/23/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/24/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/24/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/25/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/25/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/26/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/26/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/27/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/27/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/28/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/28/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/backer/29/website" target="_blank"><img src="https://opencollective.com/n1_loader/backer/29/avatar.svg"></a>

### Open Collective Sponsors

You're an organization that wants to support the project with a monthly donation. Your logo will be available on the Github page. [[Become a sponsor](https://opencollective.com/n1_loader#sponsor)]

<a href="https://opencollective.com/n1_loader/sponsor/0/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/1/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/2/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/3/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/4/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/5/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/6/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/7/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/8/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/9/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/9/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/10/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/10/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/11/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/11/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/12/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/12/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/13/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/13/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/14/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/14/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/15/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/15/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/16/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/16/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/17/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/17/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/18/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/18/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/19/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/19/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/20/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/20/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/21/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/21/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/22/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/22/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/23/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/23/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/24/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/24/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/25/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/25/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/26/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/26/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/27/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/27/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/28/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/28/avatar.svg"></a>
<a href="https://opencollective.com/n1_loader/sponsor/29/website" target="_blank"><img src="https://opencollective.com/n1_loader/sponsor/29/avatar.svg"></a>

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

[3]: https://badge.fury.io/rb/n1_loader.svg
[4]: https://badge.fury.io/rb/n1_loader
[5]: https://github.com/rails/rails/tree/main/activerecord
[6]: https://github.com/DmitryTsepelev/ar_lazy_preload
[7]: https://stackoverflow.com/questions/97197/what-is-the-n1-selects-problem-in-orm-object-relational-mapping
[8]: https://github.com/djezzzl/n1_loader
[9]: https://opencollective.com/n1_loader/tiers/badge.svg
[10]: https://opencollective.com/n1_loader#support
[11]: https://github.com/djezzzl/n1_loader/actions/workflows/tests.yml/badge.svg?branch=master
[12]: https://github.com/djezzzl/n1_loader/actions/workflows/tests.yml?query=event%3Aschedule
[13]: https://github.com/djezzzl/n1_loader/actions/workflows/rubocop.yml/badge.svg?branch=master
[14]: https://github.com/djezzzl/n1_loader/actions/workflows/rubocop.yml?query=event%3Aschedule
[15]: https://github.com/djezzzl/n1_loader#contributing
