# Stuart ML

<img src="http://downloadicons.net/sites/default/files/mouse-icon-86497.png" width="100">

A native Lua implementation of [Spark MLlib](https://spark.apache.org/docs/2.2.0/ml-guide.html).

This is a companion module for [Stuart](https://github.com/BixData/stuart), the Spark runtime for embedding and edge computing.

![Build Status](https://api.travis-ci.org/BixData/stuart-ml.svg?branch=master)

## Getting Started

### Installing

```sh
$ luarocks install stuart-ml
```

## Using

### Loading a KMeansModel

First build a model in Spark, then export it as uncompressed Parquet:

```scala
$ docker run -it gettyimages/spark bin/spark-shell --conf spark.sql.parquet.compression.codec=uncompressed

import org.apache.spark.mllib.linalg.Vector
import org.apache.spark.mllib.linalg.Vectors
import org.apache.spark.mllib.clustering.KMeans

var v1 = Vectors.dense(Array[Double](1,2,3))
var v2 = Vectors.dense(Array[Double](5,6,7))
var data = sc.parallelize(Array(v1,v2))
var model = KMeans.train(data, k=2, maxIterations=1)
model.save(sc, "model4")
```

Load the model into Stuart ML with:

```lua
local stuart = require 'stuart'
local KMeansModel = require 'stuart-ml.clustering.KMeansModel'

local sc = stuart.NewContext()
local model = KMeansModel.load(sc, 'model4')
```

### Vector Types

Vector types are 0-based, unlike Lua arrays. This facilitates a more direct translation of Scala or Python-based Apache Spark jobs and use cases to Lua.

```lua
Vectors = require 'stuart-ml.linalg.Vectors'

denseVector = Vectors.dense({0.1, 0.0, 0.3})
print(table.concat(denseVector:toArray(), ','))
{0.1,0,0.3}

sparseVector = Vectors.sparse(5, {0,1,4}, {10,11,12})
print(table.concat(sparseVector:toArray(), ','))
{10,11,0,0,12}
```

## Testing

### Testing Locally

```sh
$ busted
●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
39 successes / 0 failures / 0 errors / 0 pending : 0.068103 seconds
```

### Testing with a Specific Lua Version

```sh
$ docker build -f Test-Lua53.Dockerfile -t test .
$ docker run -it test busted
●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
39 successes / 0 failures / 0 errors / 0 pending : 0.068103 seconds
```
