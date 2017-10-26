# Stuart ML

<img src="http://downloadicons.net/sites/default/files/mouse-icon-86497.png" width="100">

A native Lua implementation of [Spark MLlib](https://spark.apache.org/docs/latest/ml-guide.html).

This is a companion module for [Stuart](https://spark.apache.org/docs/2.2.0/), the Spark runtime for embedding and edge computing.

![Build Status](https://api.travis-ci.org/BixData/stuart-ml.svg?branch=master)

## Getting Started

### Installing

```sh
$ luarocks install stuart
$ luarocks install stuart-ml
```

## Using

### Vector Types

```lua
Vectors = require 'stuart-ml.linalg.Vectors'

denseVector = Vectors.dense({0.1, 0.0, 0.3})
print(table.concat(denseVector:toArray(), ','))
{0.1,0,0.3}

sparseVector = Vectors.sparse(5, {1,2,5}, {10,11,12})
print(table.concat(sparseVector:toArray(), ','))
{10,11,0,0,12}
```

## Testing

### Testing Locally

```sh
$ busted
●●●●●●●●●●●
19 successes / 0 failures / 0 errors / 0 pending : 0.03143 seconds
```

### Testing with a Specific Lua Version

```sh
$ docker build -f Test-Lua53.Dockerfile -t test .
$ docker run -it test busted
●●●●●●●●●●●
19 successes / 0 failures / 0 errors / 0 pending : 0.03143 seconds
```
