## [0.1.3] - 2017-11-11
### Added
- `linalg:` Ported `BLAS` `axpy()`, `dot()`, and `scal()`
- `linalg:` Ported `Vectors` `sqdist()`
- `linalg:` Implement `VectorWithNorm` equality (`__eq`)
- `util:` Ported `MLUtils` `EPSILON` and `fastSquaredDistance()`

### Changed
- `linalg:` Vector types are now 0-based like Apache Spark
- Consolidate Apache Spark and Stuart unit tests into a single unified folder hierarchy

### Fixed
- `linalg:` Vector `numActives` and `numNonzeros` fields were not updating after changes to vector. `BLAS` functions mutate vectors. Changed fields to functions so that they're computed each time.

## [0.1.0] - 2017-10-28
### Added
- `clustering:` Ported `VectorWithNorm` datatype
- `linalg:` Ported `DenseVector` and `SparseVector` datatypes, plus their `Vectors` factory

<small>(formatted per [keepachangelog-1.1.0](http://keepachangelog.com/en/1.0.0/))</small>
