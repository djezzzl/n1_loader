# frozen_string_literal: true

RSpec.describe "N1Loader ActiveRecord integration" do
  require_relative "../lib/n1_loader/active_record"

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
      create_table(:employees) do |t|
        t.belongs_to :company
      end
      create_table(:assignments) do |t|
        t.belongs_to :employee
      end
    end

    stub_const("Entity", Class.new(ActiveRecord::Base) do
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

      n1_optimized :data do
        def perform(elements)
          Entity.perform!

          elements.each { |element| fulfill(element, [element]) }
        end
      end

      n1_optimized :with_arguments do
        argument :something

        def perform(elements)
          Entity.perform!

          elements.each { |element| fulfill(element, [element, something]) }
        end
      end
    end)

    stub_const("Company", Class.new(ActiveRecord::Base) do
      self.table_name = :companies

      belongs_to :entity, class_name: "Entity"
      has_many :employees, class_name: "Employee"

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

      n1_optimized :data do
        def perform(elements)
          Company.perform!

          hash = Entity.where(id: elements.map(&:entity_id)).index_by(&:id)
          elements.each { |element| fulfill(element, hash[element.entity_id]) }
        end
      end

      n1_optimized :with_arguments do
        argument :something

        def perform(elements)
          Company.perform!

          hash = Entity.where(id: elements.map(&:entity_id)).index_by(&:id)
          elements.each { |element| fulfill(element, [hash[element.entity_id], something]) }
        end
      end

      n1_optimized :with_question_mark? do
        argument :something

        def perform(elements)
          Entity.perform!

          elements.each { |element| fulfill(element, [element, something]) }
        end
      end

      n1_optimized :employee_data do 
        def perform(elements)
          Company.perform! 
          employees_hash = Employee.where(company_id: elements.map(&:id)).group_by(&:company_id)
          elements.each { |element| fulfill(element, employees_hash[element.id] || []) }
        end
      end
    end)

    stub_const("Employee", Class.new(ActiveRecord::Base) do
      self.table_name = :employees

      belongs_to :company, class_name: "Company"
      has_many :assignments, class_name: "Assignment"

      class << self
        def name
          "Employee"
        end

        def perform!
          @count = count + 1
        end

        def count
          @count || 0
        end
      end
    end)

    stub_const("Assignment", Class.new(ActiveRecord::Base) do
      self.table_name = :assignments

      belongs_to :employee, class_name: "Employee"

      class << self
        def name
          "Assignment"
        end

        def perform!
          @count = count + 1
        end

        def count
          @count || 0
        end
      end
    end)
  end

  let(:loader) do
    Class.new(N1Loader::Loader) do
      def perform(elements)
        elements.each { |element| fulfill(element, [element]) }
      end
    end
  end

  let(:object) { Entity.create! }

  it "works" do
    expect { object.data }.to change(Entity, :count).by(1)
    expect { object.data }.not_to change(Entity, :count)

    expect(object.data).to eq([object])
  end

  describe "loaded comparison" do
    it "compares by value" do
      instance = loader.new([object])

      expect(instance.for(object)).to eq([object])
      expect(instance.for(Entity.find(object.id))).to eq([object])

      expect { instance.for(Entity.create!) }.to raise_error(N1Loader::NotLoaded)
    end
  end

  describe "question mark support" do
    it "works" do
      expect do
        Company.includes(:with_question_mark?).each do |company|
          expect(company.with_question_mark?(something: "something")).to eq([company, "something"])
        end
      end.not_to raise_error
    end
  end

  context "with preloader" do
    let(:objects) { [Entity.create!, Entity.create!] }

    it "works" do
      expect { N1Loader::Preloader.new(objects).preload(:data) }.not_to change(Entity, :count)

      expect do
        objects.each do |object|
          expect(object.data).to eq([object])
        end
      end.to change(Entity, :count).by(1)
    end
  end

  context "with includes" do
    let(:objects) { Entity.includes(:data) }

    before do
      Entity.create!
      Entity.create!
    end

    it "works" do
      expect do
        objects.each do |object|
          expect(object.data).to eq([object])
        end
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(count: 1)
        .and change(Entity, :count).by(1)
    end

    context "with arguments" do
      let(:objects) { Entity.includes(:with_arguments) }

      context "without ArLazyPreload" do
        before { skip if ar_lazy_preload_defined? && !ar_version_5? }

        it "works" do
          expect do
            expect do
              objects.each do |object|
                object.with_arguments(something: "something")
              end
            end.to change(Entity, :count).by(1)
            expect do
              objects.each do |object|
                object.with_arguments(something: "something")
              end
            end.not_to change(Entity, :count)
            expect do
              objects.each do |object|
                object.with_arguments(something: "anything")
              end
            end.to change(Entity, :count).by(1)

            objects.each do |object|
              expect(object.with_arguments(something: "something")).to eq([object, "something"])
            end
          end
            .to make_database_queries(matching: /entities/, count: 1)
            .and make_database_queries(count: 1)
        end
      end

      context "with ArLazyPreload" do
        before { skip unless ar_lazy_preload_defined? && !ar_version_5? }

        it "doesn't work" do
          expect do
            objects.each do |object|
              object.with_arguments(something: "something")
            end
          end.to raise_error(N1Loader::ActiveRecord::InvalidPreloading)
        end
      end
    end
  end

  context "with nested includes" do
    let(:objects) { Entity.includes(company: %i[entity data] + [{employee_data: :assignments}]) }

    before do
      Company.create!(entity: Entity.create!, employees: [Employee.create!(assignments: [Assignment.create!])])
      Company.create!(entity: Entity.create!, employees: [Employee.create!(assignments: [Assignment.create!])])
    end

    it "works" do
      expect do
        objects.each do |object|
          expect(object.company.data).to eq(object)
        end
      end
        .to make_database_queries(matching: /entities/, count: 2)
        .and make_database_queries(matching: /companies/, count: 1)
        .and make_database_queries(matching: /employees/, count: 1)
        .and make_database_queries(matching: /assignments/, count: 1)
        .and make_database_queries(count: 5)
        .and change(Company, :count).by(2)
      objects.each do |object|
        expect(object.company.employee_data).to eq(object.company.employees)
        expect(object.company.employee_data.map(&:assignments)).to eq(object.company.employees.map(&:assignments))
      end
    end

    context "with arguments" do
      let(:objects) { Entity.includes(company: :with_arguments) }

      context "without ArLazyPreload" do
        before { skip if ar_lazy_preload_defined? && !ar_version_5? && !ar_version_7? }

        it "works" do
          expect do
            objects.each do |object|
              expect(object.company.with_arguments(something: "something")).to eq([object, "something"])
            end
          end
            .to make_database_queries(matching: /entities/, count: 2)
            .and make_database_queries(matching: /companies/, count: 1)
            .and make_database_queries(count: 3)
            .and change(Company, :count).by(1)
        end
      end

      context "with ArLazyPreload" do
        before { skip unless ar_lazy_preload_defined? && !ar_version_5? && !ar_version_7? }

        it "doesn't work" do
          expect do
            objects.each do |object|
              object.company.with_arguments(something: "something")
            end
          end.to raise_error(N1Loader::ActiveRecord::InvalidPreloading)
        end
      end
    end
  end

  context "with deep includes" do
    let(:objects) { Company.includes(data: :company) }

    before do
      Company.create!(entity: Entity.create!)
      Company.create!(entity: Entity.create!)
    end

    it "works" do
      expect do
        objects.each do |object|
          expect(object.data.company.id).to eq(object.id)
        end
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(matching: /companies/, count: 2)
        .and make_database_queries(count: 3)
        .and change(Company, :count).by(1)
    end

    context "with arguments" do
      let(:objects) { Company.includes(with_arguments: :company) }

      it "doesn't work" do
        expect do
          objects.each do |object|
            expect(object.with_arguments(something: "something").first.company.id).to eq(object.id)
          end
        end.to raise_error(N1Loader::ActiveRecord::InvalidPreloading)
      end
    end
  end
end
