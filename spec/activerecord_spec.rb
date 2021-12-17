# frozen_string_literal: true

require_relative "../lib/n1_loader/active_record"

RSpec.describe "N1Loader ActiveRecord integration" do
  before do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table, force: :cascade)
    end
    ActiveRecord::Schema.verbose = false

    ActiveRecord::Schema.define(version: 1) do
      create_table(:entities)
    end
  end

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      include N1Loader::Loadable

      self.table_name = :entities

      class << self
        def name
          "Entity"
        end

        def perform!
          @count = count + 1
        end

        def count
          @count || 0
        end
      end

      n1_load :data do |elements|
        elements.first.class.perform!
        elements.group_by(&:itself)
      end
    end
  end

  let(:object) { klass.create! }

  it "works" do
    expect { object.data }.to change(klass, :count).from(0).to(1)
    expect { object.data }.not_to change(klass, :count)

    expect(object.data).to eq([object])
  end

  context "with preloader" do
    let(:objects) { [klass.create!, klass.create!] }

    it "works" do
      N1Loader::Preloader.new(objects).preload(:data)

      expect { N1Loader::Preloader.new(objects).preload(:data) }.not_to change(klass, :count)
      expect { objects.map(&:data) }.to change(klass, :count).from(0).to(1)
      expect { objects.map(&:data) }.not_to change(klass, :count)

      expect(objects.first.data).to eq([objects.first])
      expect(objects.last.data).to eq([objects.last])
    end
  end
end
