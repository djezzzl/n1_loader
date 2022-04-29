require "sqlite3"

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

def fill_database
  10.times do
    user = User.create!
    10.times do
      Payment.create!(user: user, amount: rand(1000))
    end
  end
end