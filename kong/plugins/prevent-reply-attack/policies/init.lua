local redis = require "resty.redis"

local sock_opts = {}

local function is_present(str)
  return str and str ~= "" and str ~= null
end

local get_local_key = function(conf, identifier, val, ttl)
  return string.format("prevent-reply-attack:%s:%s:%s", identifier, val, ttl)
end

local function get_redis_connection(conf)
  local red = redis:new()
  red:set_timeout(conf.redis_timeout)
  -- use a special pool name only if redis_database is set to non-zero
  -- otherwise use the default pool name host:port
  sock_opts.pool = conf.redis_database and
    conf.redis_host .. ":" .. conf.redis_port ..
    ":" .. conf.redis_database
  local ok, err = red:connect(conf.redis_host, conf.redis_port,
    sock_opts)
  if not ok then
    kong.log.err("failed to connect to Redis: ", err)
    return nil, err
  end

  local times, err = red:get_reused_times()
  if err then
    kong.log.err("failed to get connect reused times: ", err)
    return nil, err
  end

  if times == 0 then
    if is_present(conf.redis_password) then
      local ok, err = red:auth(conf.redis_password)
      if not ok then
        kong.log.err("failed to auth Redis: ", err)
        return nil, err
      end
    end

    if conf.redis_database ~= 0 then
      -- Only call select first time, since we know the connection is shared
      -- between instances that use the same redis database

      local ok, err = red:select(conf.redis_database)
      if not ok then
        kong.log.err("failed to change Redis database: ", err)
        return nil, err
      end
    end
  end

  return red
end

return {
  ["redis"] = {
    verify = function(conf, identifier, val, ttl)
      local cache_key = get_local_key(conf, identifier, val, ttl)
      local red, err = get_redis_connection(conf)

      if not red then
        return nil, err
      end

      local ok, err = red:set(cache_key, 1, 'EX', ttl, 'NX')

      if err then
        kong.log.err("failed to commit setnx in Redis: ", err)
        return nil, err
      end

      if ok == ngx.null then
        return nil, "request refuse because of repeatable " .. conf.key
      end

      local ok, err = red:set_keepalive(10000, 100)
      if not ok then
        kong.log.err("failed to set Redis keepalive: ", err)
        return nil, err
      end

      return res
    end
  }
}
