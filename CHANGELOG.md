## [2.0.1] - 2025/12/28

- Add support of Rails 8.

## [2.0.0] - 2025/12/28

- Make loader thread-safe. 
- Make loader idempotent.

## [1.7.4] - 2023/12/18

- Fix nested association does not preload properly. Thanks [dannyongtey](https://github.com/dannyongtey) for reporting and fixing the issue!

## [1.7.3] - 2023/08/04

- Decrease the package size by 60%. 

## [1.7.2] - 2023/08/04

- Refactor core that ended up with speed boost.

## [1.7.1] - 2023/07/30

- Fix interface discrepancy for `N1LoaderReflection`. Thanks [Denis Talakevich](https://github.com/senid231) for suggesting it!

## [1.7.0] - 2023/07/30

Extend the flexibility of loading data comparison. Thanks [Nazar Matus](https://github.com/FunkyloverOne) for suggesting it! 

**BREAKING CHANGES:**

Loose comparison of loaded data. Before loaded data was initialized with identity comparator in mind:

```ruby
@loaded = {}.compare_by_identity
```

Now it will be:

```ruby
@loaded = {}
```

This might bring unwanted results for cases when strict comparison was wanted. 

On the other hand, it gives more flexibility for many other cases, especially with isolated loader.
For example, this will work now, when it wasn't working before.

```ruby
# ActiveRecord object
object = Entity.first

# Initialize isolated loader
instance = loader.new([object])

# This was working before because the loaded object is identical to passed object by `#object_id`
instance.for(object)

# This wasn't working before because the loaded object is not identical to passed one by `#object_id`
# 
# But it will be working now, because object == Entity.find(object.id)
instance.for(Entity.find(object.id))
```

If you need strict comparison support, please feel free to open the issue or the PR.

## [1.6.6] - 2023/07/30

- Fix naive check of required arguments. Thanks [Nazar Matus](https://github.com/FunkyloverOne) for the issue!

## [1.6.5] - 2023/07/30

- Fix nested preloading for ActiveRecord 7. Thanks [Igor Gonchar](https://github.com/gigorok) for the issue!

## [1.6.4] - 2023/07/30

- Add support of `n1_optimized` ending with `?` (question mark). Thanks [Ilya Kamenko](https://github.com/Galathius) for the suggestion!

## [1.6.3] - 2022/12/30

- Performance optimization: avoid unnecessary calls. Thanks [Nazar Matus](https://github.com/FunkyloverOne) for the [contribution](https://github.com/djezzzl/n1_loader/pull/33).

## [1.6.2] - 2022/11/23

- Add fund metadata

## [1.6.1] - 2022/10/29

- Fix ArLazyPreload context setup when using isolated loaders for objects without the context.

## [1.6.0] - 2022/10/24

- Add support of ArLazyPreload context for isolated loaders.

## [1.5.1] - 2022/09/20

- Fix support of falsey value of arguments. Thanks [Aitor Lopez Beltran](https://github.com/aitorlb) for the [contribution](https://github.com/djezzzl/n1_loader/pull/23)!

## [1.5.0] - 2022/05/01

- Add support of Rails 7

## [1.4.4] - 2022/04/29

- Inject `N1Loader::Loadable` to `ActiveRecord::Base` automatically
- Make `reload` to call `n1_clear_cache`

## [1.4.3] - 2022-04-13

- Add `default` support to arguments

## [1.4.2] - 2022-03-01

- Add n1_clear_cache method which is useful for cases like reload in ActiveRecord

## [1.4.1] - 2022-02-24

- Fix preloading of invalid objects

## [1.4.0] - 2022-02-22

- add support of optional arguments

BREAKING CHANGES:
- rework arguments to use single definition through `argument <name>` only
- use keyword arguments

## [1.3.0] - 2022-02-22

- add support of named arguments with `argument <name>`

BREAKING CHANGES:
- rename `n1_load` to `n1_optimized`
- rework `def self.arguments_key` to `cache_key`

## [1.2.0] - 2022-01-14

- Introduce arguments support.

## [1.1.0] - 2021-12-27

- Introduce `fulfill` method to abstract the storage.

## [1.0.0] - 2021-12-26

- Various of great features.

## [0.1.0] - 2021-12-16

- Initial release.
