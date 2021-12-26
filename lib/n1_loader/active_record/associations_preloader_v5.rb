# frozen_string_literal: true

module N1Loader
  module ActiveRecord
    module Associations
      module Preloader # :nodoc:
        N1LoaderReflection = Struct.new(:key, :loader) do
          def options
            {}
          end
        end

        def preloaders_for_one(association, records, scope)
          grouped_records(association, records).flat_map do |reflection, klasses|
            next N1Loader::Preloader.new(records).preload(reflection.key) if reflection.is_a?(N1LoaderReflection)

            klasses.map do |rhs_klass, rs|
              loader = preloader_for(reflection, rs).new(rhs_klass, rs, reflection, scope)
              loader.run self
              loader
            end
          end
        end

        def grouped_records(association, records)
          n1_load_records, records = records.partition do |record|
            record.class.respond_to?(:n1_loader_defined?) && record.class.n1_loader_defined?(association)
          end

          hash = n1_load_records.group_by do |record|
            N1LoaderReflection.new(association, record.class.n1_loader(association))
          end

          hash.merge(super)
        end
      end
    end
  end
end
