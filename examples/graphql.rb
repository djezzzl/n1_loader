# frozen_string_literal: true

require "sqlite3"
require "n1_loader/ar_lazy_preload"
require 'graphql'

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include(ArLazyPreload::Base)

  ActiveRecord::Relation.prepend(ArLazyPreload::Relation)
  ActiveRecord::AssociationRelation.prepend(ArLazyPreload::AssociationRelation)
  ActiveRecord::Relation::Merger.prepend(ArLazyPreload::Merger)

  [
    ActiveRecord::Associations::CollectionAssociation,
    ActiveRecord::Associations::Association
  ].each { |klass| klass.prepend(ArLazyPreload::Association) }

  ActiveRecord::Associations::CollectionAssociation.prepend(ArLazyPreload::CollectionAssociation)
  ActiveRecord::Associations::CollectionProxy.prepend(ArLazyPreload::CollectionProxy)
end

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
  end
  create_table(:users)
end

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
