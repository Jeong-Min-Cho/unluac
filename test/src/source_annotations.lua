local function make(value)
  return function(extra)
    return value + extra
  end
end

local object = {}
function object:apply(value)
  return make(value)(self.offset)
end

consume({
  callback = function(value)
    return value * 2
  end
}, function()
end)

return object, make
