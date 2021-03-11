local BasePlugin = require "kong.plugins.base_plugin"
local policies = require "kong.plugins.prevent-reply-attack.policies"

local EMPTY = {}

local PreventReplyAttackHandler = BasePlugin:extend()

PreventReplyAttackHandler.VERSION = "1.0.0"
PreventReplyAttackHandler.PRIORITY = 1999

local function get_identifier(conf)
  local identifier

  if conf.sign == "service" then
    identifier = (kong.router.get_service() or
      EMPTY).id

  elseif conf.sign == "consumer" then
    identifier = (kong.client.get_consumer() or
      kong.client.get_credential() or
      EMPTY).id

  elseif conf.sign == "credential" then
    identifier = (kong.client.get_credential() or
      EMPTY).id

  elseif conf.sign == "header" then
    identifier = kong.request.get_header(conf.header_name)

  elseif conf.sign == "path" then
    local req_path = kong.request.get_path()
    if req_path == conf.path then
      identifier = req_path
    end
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
    return kong.response.error(403, err)
  end
end

return PreventReplyAttackHandler
