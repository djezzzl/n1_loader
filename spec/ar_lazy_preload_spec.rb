# frozen_string_literal: true

require "rails"

return if ActiveRecord::VERSION::MAJOR >= 7

require_relative "../lib/n1_loader/ar_lazy_preload"

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

RSpec.describe "N1Loader AR Lazy Preload integration" do
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

  before do
    company_class.create!(entity: entity_class.create!)
    company_class.create!(entity: entity_class.create!)
  end

  it "works" do
    expect do
      company_class.preload_associations_lazily.all.map(&:data)
    end
      .to make_database_queries(matching: /entities/, count: 1)
      .and make_database_queries(matching: /companies/, count: 1)
      .and make_database_queries(count: 2)

    expect do
      entity_class.preload_associations_lazily.all.map(&:company).map(&:data)
    end
      .to make_database_queries(matching: /entities/, count: 2)
      .and make_database_queries(matching: /companies/, count: 1)
      .and make_database_queries(count: 3)

    expect do
      company_class.preload_associations_lazily.all.map(&:data).map(&:company)
    end
      .to make_database_queries(matching: /entities/, count: 1)
      .and make_database_queries(matching: /companies/, count: 2)
      .and make_database_queries(count: 3)

    expect do
      company_class.lazy_preload(data: :company).map(&:data).map(&:company)
    end
      .to make_database_queries(matching: /entities/, count: 1)
      .and make_database_queries(matching: /companies/, count: 2)
      .and make_database_queries(count: 3)
  end
end
