# frozen_string_literal: true

require "sqlite3"
require "n1_loader/ar_lazy_preload"

require_relative 'context/setup_ar_lazy'
require_relative 'context/setup_database'

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

fill_database

# Has N+1
p User.all.map { |user| user.payments.sum(&:amount) }

# Has no N+1 but we load too many data that we don't need
p User.preload_associations_lazily.map(&:payments_total)

# Has no N+1 and calculation is the most efficient
ArLazyPreload.config.auto_preload = true
User.all.map(&:payments_total)