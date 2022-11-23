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
