# frozen_string_literal: true

require "n1_loader"

require_relative 'context/service'

# Class that wants to request 3rd party service without N+1
class User
  include N1Loader::Loadable

  n1_optimized :optimized_call do |users|
    data = Service.receive(users)

    users.each_with_index do |user, index|
      fulfill(user, data[index])
    end
  end
end

users = [User.new, User.new, User.new]

# Without n1_bind_to: each user lazily loads independently causing N+1
count_before = Service.count
p users.map(&:optimized_call)
p "Has N+1: #{Service.count == count_before + users.count}"

users = [User.new, User.new, User.new]

# With n1_bind_to: bind users to the collection so lazy loading is automatically batched
users.each { |user| user.n1_bind_to(users) }

count_before = Service.count
p users.map(&:optimized_call)
p "Has no N+1: #{Service.count == count_before + 1}"
