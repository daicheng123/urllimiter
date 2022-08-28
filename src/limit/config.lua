local _M = {
    _VERSION = "0.0.1"

}
-- 令牌桶最大容量
local capacity = 1
-- 令牌桶令牌数
local token = 1
-- 令牌桶令牌添加速率 1/second
local rate = 1
local limit_uri = {"/limit"}

_M['capacity'] = capacity
_M['token'] = token
_M['rate'] = rate
_M['limit_uri'] = limit_uri

return _M
