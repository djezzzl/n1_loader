# frozen_string_literal: true

require "n1_loader/ar_lazy_preload"
require 'graphql'

require_relative 'context/setup_database'
require_relative 'context/setup_ar_lazy'

class User < ActiveRecord::Base
  has_many :payments

  n1_optimized :payments_total do |users|
    total_per_user = Payment.group(:user_id).where(user: users).sum(:amount).tap { |h| h.default = 0 }

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

10.times do
  user = User.create!
  10.times do
    Payment.create!(user: user, amount: rand(1000))
  end
end

ArLazyPreload.config.auto_preload = true
# Or use +preload_associations_lazily+ when loading objects from database

class UserType < GraphQL::Schema::Object
  field :payments_total, Integer
end

class QueryType < GraphQL::Schema::Object
  field  :users, [UserType]

  def users
    User.all
  end
end

class Schema < GraphQL::Schema
  query QueryType
end

query_string = <<~GQL
  {
    users {
      paymentsTotal
    }
  }
GQL

# No N+1. And never will be!
p Schema.execute(query_string)['data']
