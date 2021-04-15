local BasePlugin = require "kong.plugins.base_plugin"
local policies = require "kong.plugins.prevent-reply-attack.policies"

local EMPTY = {}

local PreventReplyAttackHandler = BasePlugin:extend()

PreventReplyAttackHandler.VERSION = "0.1.0"
PreventReplyAttackHandler.PRIORITY = 1999

local function get_identifier(conf)
  local identifier

  if conf.ident == "service" then
    identifier = (kong.router.get_service() or
      EMPTY).id

  elseif conf.ident == "consumer" then
    identifier = (kong.client.get_consumer() or
      kong.client.get_credential() or
      EMPTY).id

  elseif conf.ident == "credential" then
    identifier = (kong.client.get_credential() or
      EMPTY).id
  end

  return identifier or kong.client.get_forwarded_ip()
end

function PreventReplyAttackHandler:new()
  PreventReplyAttackHandler.super.new(self, "prevent-reply-attack")
end

function PreventReplyAttackHandler:access(conf)
  local identifier = get_identifier(conf)
  local val = kong.request.get_header(conf.key)
  local ttl = conf.ttl

  if not val then
    return kong.response.exit(400, "Bad request because of '" .. conf.key .. "' not exists")
  end

  local ok, err = policies[conf.policy].verify(conf, identifier, val, ttl)
  if err then
    kong.log.warn(err)
    if not conf.fault_tolerant then
      return kong.response.error(403, err)
    end
  end
end

return PreventReplyAttackHandler
