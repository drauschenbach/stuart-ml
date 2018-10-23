# Stuart ML - Clustering

[Clustering](https://en.wikipedia.org/wiki/Cluster_analysis) is an unsupervised learning problem whereby we aim to group subsets of entities with one another based on some notion of similarity. Clustering is often used for exploratory analysis and/or as a component of a hierarchical [supervised learning](https://en.wikipedia.org/wiki/Supervised_learning) pipeline (in which distinct classifiers or regression models are trained for each cluster).

Stuart ML supports the following models:

* [K-means](#k-means)

## K-means

[K-means](https://en.wikipedia.org/wiki/K-means_clustering) is one of the most commonly used clustering algorithms that clusters the data points into a predefined number of clusters. This implementation has the following parameters:

* _k_ is the number of desired clusters. Note that it is possible for fewer than k clusters to be returned, for example, if there are fewer than k distinct points to cluster.
* _maxIterations_ is the maximum number of iterations to run.
* _initializationMode_ specifies either random initialization or initialization via k-means||.
* _runs_ This param has no effect since Spark 2.0.0.
* _initializationSteps_ determines the number of steps in the k-means|| algorithm.
* _epsilon_ determines the distance threshold within which we consider k-means to have converged.
* _initialModel_ is an optional set of cluster centers used for initialization. If this parameter is supplied, only one run is performed.

### Examples

```lua
local KMeans = require 'stuart-ml.clustering.KMeans'
local KMeansModel = require 'stuart-ml.clustering.KMeansModel'
local moses = require 'moses'
local split = require 'stuart.util.split'
local stuart = require 'stuart'
local Vectors = require 'stuart-ml.linalg.Vectors'

local sc = stuart.NewContext()

-- Load and parse the data
local data = sc:textFile('data/mllib/kmeans_data.txt')
local parsedData = data:map(function(s)
  local tableOfNumbers = moses.map(split(s, ' '), function(str) return tonumber(str) end)
  return Vectors.dense(tableOfNumbers)
end)

-- Cluster the data into two classes using KMeans
local numClusters = 2
local numIterations = 20
local clusters = KMeans.train(parsedData, numClusters, numIterations)

-- Evaluate clustering by computing Within Set Sum of Squared Errors
local WSSSE = clusters:computeCost(parsedData)
print('Within Set Sum of Squared Errors = ' .. WSSSE)
```

<small>Find full example code at [examples/ApacheSpark/KMeansExample.lua](../examples/ApacheSpark/KMeansExample.lua).</small>

Output:

```
INFO Running Stuart (Embedded Spark 2.2.0)
INFO Local KMeans++ reached the max number of iterations: 30
INFO Local KMeans++ reached the max number of iterations: 30
INFO Iterations took 0.001201 seconds.
INFO KMeans converged in 5 iterations.
INFO The cost is 1220.931867
Within Set Sum of Squared Errors = 297.7176
```

**Apache Spark Interoperability**

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
