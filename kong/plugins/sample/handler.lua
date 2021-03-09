-- Extending the Base Plugin handler is optional, as there is no real
-- concept of interface in Lua, but the Base Plugin handler's methods
-- can be called from your child implementation and will print logs
-- in your `error.log` file (where all logs are printed).
local BasePlugin = require "kong.plugins.base_plugin"
local SampleHandler = BasePlugin:extend()

SampleHandler.VERSION = "1.0.0"
SampleHandler.PRIORITY = 10

-- Your plugin handler's constructor. If you are extending the
-- Base Plugin handler, it's only role is to instantiate itself
-- with a name. The name is your plugin name as it will be printed in the logs.
function SampleHandler:new()
  SampleHandler.super.new(self, "sample")
end

function SampleHandler:init_worker()
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  SampleHandler.super.init_worker(self)

  -- Implement any custom logic here
end


function SampleHandler:preread(config)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  SampleHandler.super.preread(self)

  -- Implement any custom logic here
end

function SampleHandler:certificate(config)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  SampleHandler.super.certificate(self)

  -- Implement any custom logic here
end

function SampleHandler:rewrite(config)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  SampleHandler.super.rewrite(self)

  -- Implement any custom logic here
end

function SampleHandler:access(config)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  SampleHandler.super.access(self)

  -- Implement any custom logic here
  kong.log.inspect(config.anonymous)
  kong.log.inspect(config.verify)
  kong.log.inspect(config.auth_key)
  kong.log.inspect(config.env)
  kong.log.inspect(config.server.host)
  kong.log.inspect(config.server.port)
end

function SampleHandler:header_filter(config)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  SampleHandler.super.header_filter(self)

  -- Implement any custom logic here
end

function SampleHandler:body_filter(config)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  SampleHandler.super.body_filter(self)

  -- Implement any custom logic here
end

function SampleHandler:log(config)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  SampleHandler.super.log(self)

  -- Implement any custom logic here
end

-- This module needs to return the created table, so that Kong
-- can execute those functions.
return SampleHandler
