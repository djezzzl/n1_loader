# frozen_string_literal: true

module N1Loader
  module ActiveRecord
    module Associations
      module Preloader # :nodoc:
        N1LoaderReflection = Struct.new(:name, :loader) do
          def options
            {}
          end
        end

        def preloaders_for_reflection(reflection, records, scope)
          return super unless reflection.is_a?(N1LoaderReflection)

          N1Loader::Preloader.new(records).preload(reflection.name)
        end

        def grouped_records(association, records, polymorphic_parent)
          n1_load_records, records = records.partition do |record|
            record.class.respond_to?(:n1_loaders) && record.class.n1_loaders[association]
          end

          hash = n1_load_records.group_by do |record|
            N1LoaderReflection.new(association, record.class.n1_loaders[association])
          end

          hash.merge(super)
        end
      end
    end
  end
end
