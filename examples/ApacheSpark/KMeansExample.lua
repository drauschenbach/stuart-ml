local KMeans = require 'stuart-ml.clustering.KMeans'
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
