# Stuart ML - Basic Statistics

* [Summary statistics](#summary-statistics)

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

