local StringTokenizer = require 'stuart-ml.util.StringTokenizer'

describe('StringTokenizer', function()

  it('handles whitespaces correctly when returning delims', function()
    local s = '(0.0, [1.0, 2.0])'
    local delims = '()[],'
    local includeDelims = true
    local tokenizer = StringTokenizer:new(s, delims, includeDelims)
    assert.equal('(', tokenizer:nextToken())
    assert.equal('0.0', tokenizer:nextToken())
    assert.equal(',', tokenizer:nextToken())
    assert.equal(' ', tokenizer:nextToken())
    assert.equal('[', tokenizer:nextToken())
    assert.equal('1.0', tokenizer:nextToken())
    assert.equal(',', tokenizer:nextToken())
    assert.equal(' 2.0', tokenizer:nextToken())
    assert.equal(']', tokenizer:nextToken())
    assert.equal(')', tokenizer:nextToken())
    assert.has_error(function() tokenizer:nextToken() end)
  end)

  it('handles whitespaces correctly when not returning delims', function()
    local s = '(0.0, [1.0, 2.0])'
    local delims = '()[],'
    local includeDelims = false
    local tokenizer = StringTokenizer:new(s, delims, includeDelims)
    assert.equal('0.0', tokenizer:nextToken())
    assert.equal(' ', tokenizer:nextToken())
    assert.equal('1.0', tokenizer:nextToken())
    assert.equal(' 2.0', tokenizer:nextToken())
    assert.has_error(function() tokenizer:nextToken() end)
  end)
end)
