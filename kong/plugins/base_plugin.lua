local Object = require "kong.vendor.classic"
local BasePlugin = Object:extend()

local ngx_log = ngx.log
local DEBUG = ngx.DEBUG
local subsystem = ngx.config.subsystem

function BasePlugin:new(name)
  self._name = name
end

-- Executed upon every Nginx worker process’s startup.
function BasePlugin:init_worker()
  ngx_log(DEBUG, "executing plugin \"", self._name, "\": init_worker")
end

if subsystem == "http" then
  -- Executed during the SSL certificate serving phase of the SSL handshake.
  function BasePlugin:certificate()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": certificate")
  end

  -- Executed for every request upon its reception from a client as a rewrite phase handler.
  -- NOTE in this phase neither the Service nor the Consumer have been identified,
  -- hence this handler will only be executed if the plugin was configured as a global plugin!
  function BasePlugin:rewrite()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": rewrite")
  end

  -- Executed for every request from a client and before it is being proxied to the upstream service.
  function BasePlugin:access()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": access")
  end

  -- Replaces both header_filter() and body_filter(). Executed after the whole response
  -- has been received from the upstream service, but before sending any part of it to the client.
  function BasePlugin:response()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": response")
  end

  -- Executed when all response headers bytes have been received from the upstream service.
  function BasePlugin:header_filter()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": header_filter")
  end

  -- Executed for each chunk of the response body received from the upstream service.
  -- Since the response is streamed back to the client, it can exceed the buffer size
  -- and be streamed chunk by chunk. hence this method can be called multiple times
  function BasePlugin:body_filter()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": body_filter")
  end
elseif subsystem == "stream" then
  -- Executed once for every connection.
  function BasePlugin:preread()
    ngx_log(DEBUG, "executing plugin \"", self._name, "\": preread")
  end
end

-- Executed when the last response byte has been sent to the client.
-- Executed once for each connection after it has been closed.
function BasePlugin:log()
  ngx_log(DEBUG, "executing plugin \"", self._name, "\": log")
end

return BasePlugin
