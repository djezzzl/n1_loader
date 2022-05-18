# Enhanced ActiveRecord

- Do you like `ActiveRecord` preloading?
- How many times have you resolved your N+1 issues with `includes` or `preload`?
- Do you know that preloading has limitations?

In this guide, I'd like to share with you tips and tricks about ActiveRecord
preloading and how you can enhance it to the next level.

Let's start by describing the models.

```ruby
# The model represents users in our application.
class User < ActiveRecord::Base
  # Every user may have from 0 to many payments.
  has_many :payments
end

# The model represents payments in our application.
class Payment < ActiveRecord::Base 
  # Every payment belongs to a user.
  belongs_to :user
end
```

Assuming we want to iterate over a group of users and check how many payments they have, we may do:

```ruby
# The query we want to use to fetch users from the database.
users = User.all
# Iteration over selected users.
users.each do |user|
  # Print amount of user's payments. 
  # This query will be called for every user, bringing an N+1 issue.
  p user.payments.count
end
```

We can fix the N+1 issue above in a second.
We need to add ActiveRecord's `includes` to the query that fetches users.

```ruby
# The query to fetch users with preload payments for every selected user.
users = User.includes(:payments).all
```

Then, we can iterate over the group again without the N+1 issue.

```ruby
users.each do |user|
  p user.payments.count
end
```

Experienced with ActiveRecord person may notice that the iteration above still will have an N+1 issue.
The reason is the `.count` method and its behavior.
This issue brings us to the first tip.

### Tip 1. `count` vs `size` vs `length`

- `count` - always queries the database with `COUNT` query;
- `size` - queries the database with `COUNT` only when there is no preloaded data, returns array length otherwise;
- `length` - always returns array length, in case there is no data, load it first.

_Note:_ be careful with `size` as ordering is critical.

Meaning, for `user = User.first`

```ruby
# Does `COUNT` query
user.payments.size
# Does `SELECT` query
user.payments.each { |payment| }
```

is different from

```ruby
# Does `SELECT` query
user.payments.each { |payment| }
# No query
user.payments.size
```

You may notice that the above solution loads all payment information when the amount is only needed.
There is a well-known solution for this case called [counter_cache](https://guides.rubyonrails.org/association_basics.html#options-for-belongs-to-counter-cache).

To use that, you need to add `payments_count` field to `users` table and adjust `Payment` model.

```ruby
# Migration to add `payments_count` to `users` table.
class AddPaymentsCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :payments_count, :integer, default: 0, null: false
  end
end

# Change `belongs_to` to have `counter_cache` option.
class Payment < ActiveRecord::Base
  belongs_to :user, counter_cache: true
end
```

_Note:_ avoid adding or removing payments from the database directly or through `insert_all`/`delete`/`delete_all` as
`counter_cache` is using ActiveRecord callbacks to update the field's value.

It's worth mentioning [counter_culture](https://github.com/magnusvk/counter_culture) alternative that has many features compared with the built-in `counter_cache`

## Associations with arguments

Now, let's assume we want to fetch the number of payments in a time frame for every user in a group.

```ruby
from = 1.months.ago
to = Time.current

# Query to fetch users.
users = User.all

users.each do |user|
  # Print the number of payments in a time frame for every user.
  # Database query will be triggered for every user, meaning it has an N+1 issue.
  p user.payments.where(created_at: from...to).count
end
```

ActiveRecord supports defining associations with arguments.

```ruby
class User < ActiveRecord::Base
  has_many :payments, -> (from, to) { where(created_at: from...to) }
end
```

Unfortunately, such associations are not possible to preload with `includes`.
Gladly, there is a solution with [N1Loader](https://github.com/djezzzl/n1_loader/).

```ruby
# Install gem dependencies.
require 'n1_loader/active_record'

class User < ActiveRecord::Base
  n1_optimized :payments_count do
    argument :from 
    argument :to 
    
    def perform(users)
      # Fetch the payment number once for all users.
      payments = Payment.where(user: users).where(created_at: from...to).group(:user_id).count
      
      users.each do |user|
        # Assign preloaded data to every user. 
        # Note: it doesn't use any promises.
        fulfill(user, payments[user.id])
      end
    end
  end
end

from = 1.month.ago 
to = Time.current

# Preload `payments` N1Loader "association". Doesn't query the database yet.
users = User.includes(:payments_count).all

users.each do |user|
  # Queries the database once, meaning has no N+1 issues.
  p user.payments_count(from, to)
end
```

Let's look at another example. Assuming we want to fetch the last payment for every user.
We can try to define scoped `has_one` association and use that.

```ruby
class User < ActiveRecord::Base
  has_one :last_payment, -> { order(id: :desc) }, class_name: 'Payment'
end
```

We can see that preloading is working.

```ruby
users = User.includes(:last_payment)

users.each do |user|
  # No N+1. Last payment was returned.
  p user.last_payment
end
```

At first glance, we may think everything is alright. Unfortunately, it is not.

### Tip 2. Enforce `has_one` associations on the database level

ActiveRecord, fetches all available payments for every user with provided order and then assigns only first payment to the association.
First, such querying is inefficient as we load many redundant information.
But most importantly, this association may lead to big issues. Other engineers may use it, for example,
for `joins(:last_payment)`. Assuming that association has strict agreement on the database level that
a user may have none or a single payment in the database. Apparently, it may not be the case, and some queries
will return unexpected data.

Described issues may be found with [DatabaseConsistency](https://github.com/djezzzl/database_consistency).

Back to the task, we can solve it with [N1Loader](https://github.com/djezzzl/n1_loader) in the following way

```ruby
require 'n1_loader/active_record'

class User < ActiveRecord::Base
  n1_optimized :last_payment do |users|
    subquery = Payment.select('MAX(id)').where(user: users)
    payments = Payment.where(id: subquery).index_by(&:user_id)
    
    users.each do |user|
      fulfill(user, payments[user.id])
    end
  end
end

users = User.includes(:last_payment).all

users.each do |user|
  # Queries the database once, meaning no N+1.
  p user.last_payment
end
```

Attentive reader could notice that in every described case, it was a requirement to explicitly list data that we want to preload for a group of users.
Gladly, there is a simple solution! [ArLazyPreload](https://github.com/DmitryTsepelev/ar_lazy_preload) will make N+1 disappear just by enabling it.
As soon as you need to load association for any record, it will load it once for all records that were fetched along this one.
And it works with ActiveRecord and N1Loader perfectly!

Let's look at the example.

```ruby
# Require N1Loader with ArLazyPreload integration
require 'n1_loader/ar_lazy_preload'

# Enable ArLazyPreload globally, so you don't need to care about `includes` anymore
ArLazyPreload.config.auto_preload = true

class User < ActiveRecord::Base
  has_many :payments

  n1_optimized :last_payment do |users|
    subquery = Payment.select('MAX(id)').where(user: users)
    payments = Payment.where(id: subquery).index_by(&:user_id)

    users.each do |user|
      fulfill(user, payments[user.id])
    end
  end
end

# no need to specify `includes`
users = User.all

users.each do |user|
  p user.payments # no N+1
  p user.last_payment # no N+1
end
```

As you can see, there is no need to even remember about resolving N+1 when you have both [ArLazyPreload](https://github.com/DmitryTsepelev/ar_lazy_preload) and [N1Loader](https://github.com/djezzzl/n1_loader) in your pocket.
It works great with GraphQL API too. Give it and try and share your feedback!