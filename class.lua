local getmetatable = getmetatable
local setmetatable = setmetatable

local function first_new(self, obj)
  self.mt = {__index = self}
  self.super = getmetatable(self).__index
  self.new = nil
  return self:subsequent_new(obj)
end

local function subsequent_new(self, obj)
  obj = obj or {}
  setmetatable(obj, self.mt)
  obj.new = first_new
  return obj
end

local class = {
  first_new = first_new,
  subsequent_new = subsequent_new,
  new = subsequent_new
}
class.mt = {__index = class}

return class