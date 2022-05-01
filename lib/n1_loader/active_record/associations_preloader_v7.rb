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

        def preloaders_for_reflection(reflection, records)
          return super unless reflection.is_a?(N1LoaderReflection)

          N1Loader::Preloader.new(records).preload(reflection.key)
        end

        def grouped_records
          n1_load_records, records = source_records.partition do |record|
            record.class.respond_to?(:n1_loader_defined?) && record.class.n1_loader_defined?(association)
          end

          h = n1_load_records.group_by do |record|
            N1LoaderReflection.new(association, record.class.n1_loader(association))
          end

          polymorphic_parent = !root? && parent.polymorphic?
          records.each do |record|
            reflection = record.class._reflect_on_association(association)
            next if polymorphic_parent && !reflection || !record.association(association).klass
            (h[reflection] ||= []) << record
          end
          h
        end
      end
    end
  end
end
