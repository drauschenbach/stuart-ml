local NumericParser = require 'stuart-ml.util.NumericParser'

describe('Apache Spark MLlib - NumericParserSuite', function()

  it('parser', function()
    local s = '((1.0,2e3),-4,[5e-6,7.0E8],+9)'
    local parsed = NumericParser.parse(s)
    assert.same({1.0, 2.0e3}, parsed[1])
    assert.equal(-4.0, parsed[2])
    assert.same({5.0e-6, 7.0e8}, parsed[3])
    assert.equal(9.0, parsed[4])
  end)
  
  it('parser handling of malformatted content', function()
    assert.has_error(function() NumericParser.parse('a') end)
    assert.has_error(function() NumericParser.parse('[1,,]') end)
    assert.has_error(function() NumericParser.parse('0.123.4') end)
    assert.has_error(function() NumericParser.parse('1 2') end)
    assert.has_error(function() NumericParser.parse('3+4') end)
  end)

  it('parser with whitespaces', function()
    local s = '(0.0, [1.0, 2.0])'
    local parsed = NumericParser.parse(s)
    assert.equal(0.0, parsed[1])
    assert.same({1.0, 2.0}, parsed[2])
  end)
end)
