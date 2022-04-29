# This is needed as for now ArLazyPreload requires Rails application
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