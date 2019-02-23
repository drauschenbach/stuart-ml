# Training a Spark K-means model within Redis

This example shows how to make use of Stuart ML within Redis to train an Apache Spark K-means model. It does not make use of any Redis data structures, and only aims to illustrate use of Stuart ML within the Redis execution environment.

```sh
$ redis-cli --eval train-with-dependencies.lua 0,0
```

## Developing

The amalgamated `train-with-dependencies.lua` was produced as follows:

### Step 1: Install Lua Amalgamator for Redis

```sh
$ luarocks install amalg-redis
```

### Step 2: Generate `amalg.cache` file

Using your local OS and its Lua VM, perform a trial run of your Spark job, while allowing `amalg-redis` to capture the module dependencies that are used during execution.

```sh
$ lua -lamalg-redis train.lua

INFO Running Stuart (Embedded Spark 2.2.0)
INFO Iterations took 0.001644 seconds.
INFO KMeans converged in 4 iterations.
INFO The cost is 491.169200

Model:	KMeansModel(clusterCenters=1,2)
  center 1 (3.0333333333333,0.033333333333333)
  center 2 (4.55,0.05)

Predicts:
  point (0,0)    ==> center 1 (3.0333333333333,0.033333333333333)
  point (0,0.1)  ==> center 1 (3.0333333333333,0.033333333333333)
  point (0.1,0)  ==> center 1 (3.0333333333333,0.033333333333333)
  point (9,0)    ==> center 2 (4.55,0.05)
  point (9,0.2)  ==> center 2 (4.55,0.05)
  point (9.2,0)  ==> center 2 (4.55,0.05)
```

This produces an `amalg.cache` file in the current directory, which is required by the amalgamation process.

### Step 3: Amalgamate the Spark job with its dependencies

```sh
$ amalg-redis.lua -s train.lua -o train-with-dependencies.lua -c -i "^socket"
```

### Step 4: Run it

```sh
$ redis-cli --eval train-with-dependencies.lua 0,0
```

And view the output:

```sh
$ tail /usr/local/var/redis.log

22385:M 23 Feb 2019 12:48:23.898 - Accepted 127.0.0.1:49901
INFO Running Stuart (Embedded Spark 2.2.0)
INFO Local KMeans++ reached the max number of iterations: 30
INFO Local KMeans++ reached the max number of iterations: 30
INFO KMeans converged in 4 iterations.
INFO The cost is 320.460000

Model:	KMeansModel(clusterCenters=1,2)
  center 1 (3.0333333333333,0.033333333333333)
  center 2 (4.55,0.05)

Predicts:
  point (0,0)    ==> center 1 (3.0333333333333,0.033333333333333)
  point (0,0.1)  ==> center 1 (3.0333333333333,0.033333333333333)
  point (0.1,0)  ==> center 1 (3.0333333333333,0.033333333333333)
  point (9,0)    ==> center 2 (4.55,0.05)
  point (9,0.2)  ==> center 2 (4.55,0.05)
  point (9.2,0)  ==> center 2 (4.55,0.05)

22385:M 23 Feb 2019 12:48:23.913 - Client closed connection
```
