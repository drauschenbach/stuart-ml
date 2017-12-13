# stuart-ml spec-fixtures/model2

Generated with:

```scala
$ docker run -it gettyimages/spark bin/spark-shell \
	--conf spark.sql.parquet.compression.codec=uncompressed

import org.apache.spark.mllib.linalg.Vector
import org.apache.spark.mllib.linalg.Vectors
import org.apache.spark.mllib.clustering.KMeans

var v1 = Vectors.dense(Array[Double](1,2,3))
var v2 = Vectors.dense(Array[Double](5,6,7))
var data = sc.parallelize(Array(v1,v2))
var model = KMeans.train(data, k=1, maxIterations=1)
model.save(sc, "model2")
```