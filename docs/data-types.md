# Stuart ML - Data types

* [Vector](#vector)

## Vector

A vector has numeric-typed and 0-based indices (unlike 1-based Lua arrays) and numeric-typed values. Stuart ML supports two types of vectors: dense and sparse. A dense vector is backed by a double array representing its entry values, while a sparse vector is backed by two parallel arrays: indices and values. For example, a vector `{1.0, 0.0, 3.0}` can be represented in dense format as `{1.0, 0.0, 3.0}` or in sparse format as `{3, {0, 2}, {1.0, 3.0}}`, where 3 is the size of the vector.

The base class of local vectors is `Vector`, and we provide two implementations: `DenseVector` and `SparseVector`. We recommend using the factory methods implemented in `Vectors` to create vectors.

```lua
Vectors = require 'stuart-ml.linalg.Vectors'

denseVector = Vectors.dense({0.1, 0.0, 0.3})
print(denseVector)
0.1,0,0.3

sparseVector = Vectors.sparse(5, {0,1,4}, {10,11,12})
print(sparseVector)
10,11,0,0,12
```
