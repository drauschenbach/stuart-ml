# Publishing to npmjs.com

## 1. Login

```sh
$ npm login
...
```

## 2. Prepare amalgamated Lua file

```sh
$ lua amalgamate.lua ../../rockspecs/stuart-ml-0.1.8-0.rockspec
```

This generates `stuart-ml.lua`, `package.json`, and `lua-stuart-ml.tgz` files.

## 3. Upload to npmjs.com

```sh
$ npm publish lua-stuart-ml.tgz
```
