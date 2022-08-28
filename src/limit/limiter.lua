local bucket_manager = require("limit.bucket")
local strings = require "string"
local json = require "cjson.safe"
local shared_data = ngx.shared.data
local config = require("limit.config")

local function logger(level, message)
    ngx.log(level, message)
    if level == ngx.ERR  then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

local function parseJsonData(d)
    return json.decode(d)
end

local function encodeJsonData(d)
    return json.encode(d)
end

_M = {
    _VERSION = "0.0.1"
}

local mt = { __index = _M }

function _M.newLimitBucket(_,capacity, token, rate, lastTime)
    return bucket_manager:new(capacity, token, rate, lastTime)
end

function _M.updateKeyToCache(self,remote, uri, bucket)
    local bucketStr = encodeJsonData(bucket)
    if bucketStr == nil then
        local msg = strings.format("remote:%s, url:%s encode bucket to str err", remote, uri)
        logger(ngx.ERR, msg)
    end

    local remote_key = remote .. '-' .. uri
    local ok, err, _ = shared_data:set(remote_key, bucketStr, 0)
    if not ok then
        local msg = strings.format("remote:%s, url:%s set limit bucket err:[%s]", remote_key, uri, err)
        logger(ngx.ERR, msg)
    end
    local keyTest = shared_data:get(remote_key)
end

function _M.getKeyFromCache(self, remote, uri)
    local remote_key = remote .. '-' .. uri
    local bucketStr = shared_data:get(remote_key)
    if bucketStr then
        local obj = parseJsonData(bucketStr)
        local bucket = self:newLimitBucket(
            obj['capacity'],
            obj['token'],
            obj['rate'],
            obj['lastTime'])
        return bucket
    else
        local bucket = self:newLimitBucket(
            config['capacity'],
            config['token'],
            config['rate'],
            ngx.now())
        return bucket
    end
end


function _M.run(self)
    if ngx.req.is_internal() then
        return
    end

    local uri = ngx.var.uri
    local limit_uri = config['limit_uri']
    for _, v in ipairs(limit_uri) do
        if v == uri then
            local headers = ngx.req.get_headers()
            local remote = headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0"
            local bucket = self:getKeyFromCache(remote, uri)
            
            local ok = bucket:is_accept()
            self:updateKeyToCache(remote, uri, bucket)

            if not ok then
                local msg = strings.format("remote:%s access uri:[%s] rate is too fast.", remote, uri)
                logger(ngx.WARN, msg)
                ngx.exit(ngx.HTTP_TOO_MANY_REQUESTS)
                return
          end
      end
  end
end

return _M
