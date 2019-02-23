# Unit testing within Redis

The [stuart-ml-elua](https://github.com/BixData/stuart-ml-elua) project provides self-contained test suites such as [test/stuartml\_util\_MLUtils.lua](https://github.com/BixData/stuart-ml-elua/blob/2.0.0-0/test/stuartml_util_MLUtils.lua) which are well-suited to being sent into Redis to report on test coverage.

A test run shows up in the Redis log like this:

```
22385:M 23 Feb 2019 07:00:31.248 - Accepted 127.0.0.1:63727
Begin test
✓ epsilon computation
✖ fast squared distance
  FAILED: user_script:2954: attempt to call field 'type' (a nil value)
End of test: 1 failures
22385:M 23 Feb 2019 07:00:31.250 - Client closed connection
```

## Configure Redis to show debug logging

Lua print statements will show up in the Redis log by setting `loglevel debug` within `redis.conf`.

On a Mac using the Homebrew distribution of Redis:

```sh
$ sudo vi /usr/local/etc/redis.conf
loglevel debug
$ brew services restart redis
$ tail -f /usr/local/var/log/redis.log
```

## Developing

### Step 1: Download the Lua Amalgamator for Redis

```sh
$ luarocks install amalg-redis
```

### Step 2: Generate an `amalg.cache` file

Using your local OS and its Lua VM, perform a trial run of the class framework test suite, while allowing `amalg-redis` to capture the module dependencies that are used during execution.

```sh
$ lua -lamalg-redis stuartml_util_MLUtils.lua
Begin test
✓ epsilon computation
✖ fast squared distance
  FAILED: user_script:2954: attempt to call field 'type' (a nil value)
End of test: 1 failures
```

This produces an `amalg.cache` file in the current directory, which is used by the amalgamation process.

### Step 3: Amalgamate the test suite with its dependencies

```sh
$ amalg-redis.lua -s stuartml_util_MLUtils.lua -o stuartml_util_MLUtils-with-dependencies.lua -c
```

## Running a test suite

Tail the Redis log in one shell session:

```sh
$ tail -f /usr/local/var/log/redis.log
```

Then submit the test suite in another:

```sh
$ redis-cli --eval stuartml_util_MLUtils-with-dependencies.lua 0,0
```

## Suite: stuartml\_clustering\_kmeans

	$ redis-cli --eval stuartml_clustering_KMeans-with-dependencies.lua 0,0

```
Begin test
✓ findClosest() with exact match works
✓ findClosest() with near match works
End of test: 0 failures
```

## Suite: stuartml\_linalg\_BLAS

	$ redis-cli --eval stuartml_linalg_BLAS-with-dependencies.lua 0,0

```
Begin test
✓ numNonzeros is accurate after axpy() changes the vector
End of test: 0 failures
```

## Suite: stuartml\_linalg\_Matrices

	$ redis-cli --eval stuartml_linalg_Matrices-with-dependencies.lua 0,0

```
Begin test
✓ dense matrix construction
✓ dense matrix construction with wrong dimension
✓ sparse matrix construction
✓ sparse matrix construction with wrong number of elements
✓ index in matrices incorrect input
✓ matrix indexing and updating
✓ toSparse, toDense
✓ map, update
✓ transpose
✓ foreachActive
✓ zeros
✓ ones
✓ eye
✓ diag
✓ numNonzeros and numActives
End of test: 0 failures
```

## Suite: stuartml\_linalg\_Vectors

	$ redis-cli --eval stuartml_linalg_Vectors-with-dependencies.lua 0,0

```
Begin test
✓ dense vector construction with varargs
✓ sparse vector construction
✓ sparse vector construction with unordered elements
✓ sparse vector construction with mismatched indices/values array
✓ sparse vector construction with too many indices vs size
✓ dense to array
✓ dense argmax
✓ sparse to array
✓ sparse argmax
✓ vector equals
✓ vectors equals with explicit 0
✓ indexing dense vectors
✓ indexing sparse vectors
End of test: 0 failures
```

## Suite: util_MLUtils

	$ redis-cli --eval stuartml_util_MLUtils-with-dependencies.lua 0,0

```
Begin test
✓ epsilon computation
✓ fast squared distance
End of test: 0 failures
```

## Related

* [moses-elua](https://github.com/BixData/moses-elua)
* [stuart-elua](https://github.com/BixData/stuart-elua)
* [stuart-ml-elua](https://github.com/BixData/stuart-ml-elua)
