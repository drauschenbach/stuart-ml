package = "stuart-ml"
version = "0.1.0-0"
source = {
   url = "https://github.com/BixData/stuart-ml/archive/0.1.0-0.tar.gz",
   dir = "stuart-ml-0.1.0-0"
}
description = {
   summary = "A native Lua implementation of Spark MLlib",
   detailed = [[
      A native Lua implementation of Spark MLlib, designed for
      use with Stuart, the Spark runtime for embedding and edge
      computing.
   ]],
   homepage = "https://github.com/BixData/stuart-ml",
   maintainer = "David Rauschenbach",
   license = "Apache 2.0"
}
dependencies = {
   "lua >= 5.1",
   "stuart < 0.2.0"
}
build = {
   type = "builtin",
   modules = {
      stuart = "src/stuart-ml.lua"
   }
}
