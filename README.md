# Stuart ML

<img src="http://downloadicons.net/sites/default/files/mouse-icon-86497.png" width="100">

A native Lua implementation of [Spark MLlib](https://spark.apache.org/docs/2.2.0/ml-guide.html). This is a companion module for [Stuart](https://github.com/BixData/stuart), the Spark runtime for embedding and edge computing.

[![License](http://img.shields.io/badge/Licence-Apache%202.0-blue.svg)](LICENSE)
[![Lua](https://img.shields.io/badge/Lua-5.1%20|%205.2%20|%205.3%20|%20JIT%202.0%20|%20JIT%202.1%20|%20Fengari%20|%20GopherLua-blue.svg)]()
![Build Status](https://api.travis-ci.org/BixData/stuart-ml.svg?branch=master)

## Getting Started

### Installing

```sh
$ luarocks install stuart-ml
```

## API Guide

* [Data types](#data-types)
* [Basic statistics](#basic-statistics)
* [Clustering](#clustering)

### Data types

#### Vector

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

### Basic statistics

* [Summary statistics](#summary-statistics)

#### Summary statistics

We provide column summary statistics for RDDs through the function `colStats()` available in the `stuart-ml.stat.statistics` module.

`colStats()` returns an instance of `MultivariateStatisticalSummary`, which contains the column-wise max, min, mean, variance, and number of nonzeros, as well as the total count.

```lua
local Vectors = require 'stuart-ml.linalg.Vectors'
local sc = require 'stuart'.NewContext()

local observations = sc:parallelize({
	Vectors.dense(1.0, 10.0, 100.0),
	Vectors.dense(2.0, 20.0, 200.0),
	Vectors.dense(3.0, 30.0, 300.0)
})
local summary = statistics.colStats(observations)

print(summary:mean()) -- a dense vector containing the mean value for each column
{2,20,200}

print(summary:variance()) -- column-wise variance
... TODO ...

print(summary:numNonzeros()) -- number of nonzeros in each column
{3,3,3}
```

### Clustering

[Clustering](https://en.wikipedia.org/wiki/Cluster_analysis) is an unsupervised learning problem whereby we aim to group subsets of entities with one another based on some notion of similarity. Clustering is often used for exploratory analysis and/or as a component of a hierarchical [supervised learning](https://en.wikipedia.org/wiki/Supervised_learning) pipeline (in which distinct classifiers or regression models are trained for each cluster).

Stuart ML supports the following models:

* [K-means](#k-means)

### K-means

[K-means](https://en.wikipedia.org/wiki/K-means_clustering) is one of the most commonly used clustering algorithms that clusters the data points into a predefined number of clusters. This implementation has the following parameters:

* _k_ is the number of desired clusters. Note that it is possible for fewer than k clusters to be returned, for example, if there are fewer than k distinct points to cluster.
* _maxIterations_ is the maximum number of iterations to run.
* _initializationMode_ specifies either random initialization or initialization via k-means||.
* _runs_ This param has no effect since Spark 2.0.0.
* _initializationSteps_ determines the number of steps in the k-means|| algorithm.
* _epsilon_ determines the distance threshold within which we consider k-means to have converged.
* _initialModel_ is an optional set of cluster centers used for initialization. If this parameter is supplied, only one run is performed.

#### Examples

First build a model in Apache Spark's `spark-shell`, then export it as uncompressed Parquet:

```scala
$ docker run -it gettyimages/spark:2.2.0-hadoop-2.7 bin/spark-shell \
	--conf spark.sql.parquet.compression.codec=uncompressed

import org.apache.spark.mllib.linalg.Vector
import org.apache.spark.mllib.linalg.Vectors
import org.apache.spark.mllib.clustering.KMeans

var v1 = Vectors.dense(Array[Double](1,2,3))
var v2 = Vectors.dense(Array[Double](5,6,7))
var data = sc.parallelize(Array(v1,v2))
var model = KMeans.train(data, k=2, maxIterations=1)
model.save(sc, "model4")
```

Then load the model into Stuart ML with:

```lua
local stuart = require 'stuart'
local KMeansModel = require 'stuart-ml.clustering.KMeansModel'

local sc = stuart.NewContext()
local model = KMeansModel.load(sc, 'model4')
```

The model loader requires the Stuart SQL support module, which can be installed with:

```sh
$ luarocks install stuart-sql
```

## Testing

### Testing Locally

```sh
$ busted -v
●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
62 successes / 0 failures / 0 errors / 0 pending : 0.252009 seconds
```

### Testing with a Specific Lua Version

```sh
$ docker build -f Test-Lua5.3.Dockerfile -t test .
$ docker run -it test busted -v
●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
62 successes / 0 failures / 0 errors / 0 pending : 0.252009 seconds
```
