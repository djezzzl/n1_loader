# frozen_string_literal: true

require "n1_loader/ar_lazy_preload"

require_relative 'context/setup_ar_lazy'
require_relative 'context/setup_database'

class Loader < N1Loader::Loader
  def perform(users)
    total_per_user = Payment.group(:user_id).where(user: users).sum(:amount).tap { |h| h.default = 0 }

    users.each do |user|
      total = total_per_user[user.id]
      fulfill(user, total)
    end
  end
end

class User < ActiveRecord::Base
  has_many :payments
end

class Payment < ActiveRecord::Base
  belongs_to :user

  validates :amount, presence: true
end

fill_database

# Has N+1 and loads redundant data
p User.all.map { |user| user.payments.sum(&:amount) }

# Has no N+1 and loads only required data
p User.preload_associations_lazily.all.map { |user| Loader.for(user) }

# or
ArLazyPreload.config.auto_preload = true
p User.all.map { |user| Loader.for(user) }
