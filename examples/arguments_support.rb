# frozen_string_literal: true

require "sqlite3"
require "n1_loader/active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.drop_table(table, force: :cascade)
end
ActiveRecord::Schema.verbose = false
ActiveRecord::Base.logger = Logger.new($stdout)

ActiveRecord::Schema.define(version: 1) do
  create_table(:payments) do |t|
    t.belongs_to :user
    t.integer :amount
    t.timestamps
  end
  create_table(:users)
end

class User < ActiveRecord::Base
  has_many :payments

  n1_optimized :payments_total do
    # Arguments can be:
    # argument :something, optional: true
    # argument :something, default: -> { 100 }
    #
    # Note: do not use mutable (mostly timing related) defaults like:
    # argument :from, default -> { 2.minutes.from_now }
    # because such values will be unique for every loader call which will make N+1 issue stay
    argument :from
    argument :to

    # This is used to define logic how loaders are compared to each other
    # default is:
    # cache_key { *arguments.map(&:object_id) }
    cache_key { [from, to] }

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

10.times do
  user = User.create!
  10.times do
    Payment.create!(user: user, amount: rand(1000))
  end
end

from = 2.days.ago
to = 1.day.ago

# Has N+1
p User.all.map { |user|
  user.payments.select do |payment|
    payment.created_at >= from && payment.created_at <= to
  end.sum(&:amount)
}
# Has no N+1 but we load too many data that we don't need
p User.all.includes(:payments).map { |user|
  user.payments.select do |payment|
    payment.created_at >= from && payment.created_at <= to
  end.sum(&:amount)
}
# Has no N+1 and calculation is the most efficient
p User.all.includes(:payments_total).map { |user| user.payments_total(from: from, to: to) }
