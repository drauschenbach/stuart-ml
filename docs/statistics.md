# Stuart ML - Basic Statistics

* [Summary statistics](#summary-statistics)
* [Correlations](#correlations)

## Summary statistics

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

## Correlations

Calculating the correlation between two series of data is a common operation in statistics. In Stuart ML we provide the flexibility to calculate pairwise correlations among many series. The supported correlation method is currently Pearson’s correlation.

The `stuart-ml.stat.statistics` module provides methods to calculate correlations between series. Depending on the type of input, two RDD[Number]s or an RDD[Vector], the output will be a Number or the correlation Matrix respectively.

```lua
local statistics = require 'stuart-ml.stat.statistics'
local sc = require 'stuart'.NewContext()
local Vectors = require 'stuart-ml.linalg.Vectors'

local seriesX = sc:parallelize({1, 2, 3, 3, 5})  
local seriesY = sc:parallelize({11, 22, 33, 33, 555})

-- compute the correlation using Pearson's method
local correlation = statistics.corr(seriesX, seriesY, 'pearson')
print('Correlation is', correlation))

local data = sc:parallelize({
  Vectors.dense(1.0, 10.0, 100.0),
  Vectors.dense(2.0, 20.0, 200.0),
  Vectors.dense(5.0, 33.0, 366.0))
})  -- note that each Vector is a row and not a column

-- calculate the correlation matrix using Pearson's method
local correlMatrix = statistics.corr(data, 'pearson')
print(correlMatrix)
```
