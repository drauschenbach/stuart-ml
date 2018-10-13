## [Unreleased]
### Added
- Lua 5.3 support
- `stat:` Ported `MultivariateOnlineSummarizer`

### Changed
- [#15](https://github.com/BixData/stuart-ml/issues/15) Remove stuart-sql LuaRocks dependency. It is still used when present, but no longer required.

## [0.1.7] - 2018-10-12
### Changed
- Upgrade to Stuart 0.1.7

## [0.1.5] - 2017-12-12
### Added
- `clustering:` Ported `KMeansModel`
- `util:` Ported `Loader`, which can load a `KMeansModel` from a Parquet file or directory of files, whether local or WebHDFS
- `util:` Ported `NumericParser`
- `util:` Ported `StringTokenizer`

## [0.1.3] - 2017-11-11
### Added
- `clustering:` Ported `KMeans` `fastSquaredDistance()`, `findClosest()` and `pointCost()`
- `linalg:` Ported `BLAS` `axpy()`, `dot()`, and `scal()`
- `linalg:` Ported `Vectors` `sqdist()`
- `linalg:` Implement `VectorWithNorm` equality (`__eq`)
- `util:` Ported `MLUtils` `EPSILON` and `fastSquaredDistance()`

### Changed
- `clustering:` Fixed KMeans getters and setters to match RDD API, not DataFrame API
- `linalg:` Vector types are now 0-based like Apache Spark
- Consolidate Apache Spark and Stuart unit tests into a single unified folder hierarchy

### Fixed
- `linalg:` Vector `numActives` and `numNonzeros` fields were not updating after changes to vector. `BLAS` functions mutate vectors. Changed fields to functions so that they're computed each time.

## [0.1.0] - 2017-10-28
### Added
- `clustering:` Ported `VectorWithNorm` datatype
- `linalg:` Ported `DenseVector` and `SparseVector` datatypes, plus their `Vectors` factory

<small>(formatted per [keepachangelog-1.1.0](http://keepachangelog.com/en/1.0.0/))</small>
