# frozen_string_literal: true

require "active_record"

return if ActiveRecord::VERSION::MAJOR >= 7

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
      create_table(:companies) do |t|
        t.belongs_to :entity
      end
    end
  end

  let!(:entity_class) do
    stub_const("Entity", Class.new(ActiveRecord::Base) do
      include N1Loader::Loadable

      self.table_name = :entities

      has_one :company, class_name: "Company"

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
    end)
  end

  let!(:company_class) do
    stub_const("Company", Class.new(ActiveRecord::Base) do
      include N1Loader::Loadable

      self.table_name = :companies

      belongs_to :entity, class_name: "Entity"

      class << self
        def name
          "Company"
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

        hash = Entity.where(id: elements.map(&:entity_id)).index_by(&:id)
        hash.transform_keys! { |key| elements.find { |element| element.entity_id == key } }
      end
    end)
  end

  let(:object) { entity_class.create! }

  it "works" do
    expect { object.data }.to change(entity_class, :count).from(0).to(1)
    expect { object.data }.not_to change(entity_class, :count)

    expect(object.data).to eq([object])
  end

  context "with preloader" do
    let(:objects) { [entity_class.create!, entity_class.create!] }

    it "works" do
      expect { N1Loader::Preloader.new(objects).preload(:data) }.not_to change(entity_class, :count)
      expect { objects.map(&:data) }.to change(entity_class, :count).from(0).to(1)
      expect { objects.map(&:data) }.not_to change(entity_class, :count)

      expect(objects.first.data).to eq([objects.first])
      expect(objects.last.data).to eq([objects.last])
    end
  end

  context "with includes" do
    let(:objects) { entity_class.includes(:data) }

    before do
      entity_class.create!
      entity_class.create!
    end

    it "works" do
      expect do
        expect { objects.map(&:data) }.to change(entity_class, :count).from(0).to(1)
        expect { objects.map(&:data) }.not_to change(entity_class, :count)

        expect(objects.first.data).to eq([objects.first])
        expect(objects.last.data).to eq([objects.last])
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(count: 1)
    end
  end

  context "with nested includes" do
    let(:objects) { entity_class.includes(company: :data) }

    before do
      company_class.create!(entity: entity_class.create!)
      company_class.create!(entity: entity_class.create!)
    end

    it "works" do
      expect do
        expect { objects.map(&:company).map(&:data) }.to change(company_class, :count).from(0).to(1)
        expect { objects.map(&:company).map(&:data) }.not_to change(company_class, :count)

        expect(objects.first.company.data).to eq(objects.first)
        expect(objects.last.company.data).to eq(objects.last)
      end
        .to make_database_queries(matching: /entities/, count: 2)
        .and make_database_queries(matching: /companies/, count: 1)
        .and make_database_queries(count: 3)
    end
  end

  context "with deep includes" do
    let(:objects) { company_class.includes(data: :company) }

    before do
      company_class.create!(entity: entity_class.create!)
      company_class.create!(entity: entity_class.create!)
    end

    it "works" do
      expect do
        expect { objects.map(&:data).map(&:company) }.to change(company_class, :count).from(0).to(1)
        expect { objects.map(&:data).map(&:company) }.not_to change(company_class, :count)

        expect(objects.first.data.company.id).to eq(objects.first.id)
        expect(objects.last.data.company.id).to eq(objects.last.id)
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(matching: /companies/, count: 2)
        .and make_database_queries(count: 3)
    end
  end
end
