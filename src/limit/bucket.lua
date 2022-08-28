local setmetatable = setmetatable
local config = require("limit.config")
local math = require( "math")
_M = {
    _VERSION = "0.0.1"
}

local mt = {
    __index = _M
}


function _M.is_accept(self)
    local now = ngx.now()
    local number = math.floor((now - self.lastTime) * self.rate)
    self.token = self.token + number
    ngx.log(ngx.INFO, "number: ", number, now, self.lastTime,  now - self.lastTime, "---333333333")
    if self.token > self.capacity then
        self.token = self.capacity
    end

     self.lastTime = now
     if self.token > 0 then
        self.token = self.token - 1
        return true
     end
     return false
end

function _M.new(self, capacity, token, rate,lastTime)
   local s = {
        capacity  = capacity,
        token = token,
        rate = rate,
        lastTime = lastTime
   }
   return setmetatable(s, mt)
end

return _M
