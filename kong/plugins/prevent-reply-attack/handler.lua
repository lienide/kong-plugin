local policies = require "kong.plugins.prevent-reply-attack.policies"

local PreventReplyAttackHandler = {}
local EMPTY = {}

PreventReplyAttackHandler.VERSION = "1.0.0"
PreventReplyAttackHandler.PRIORITY = 10

local function get_identifier(conf)
  local identifier

  if conf.limit_by == "service" then
    identifier = (kong.router.get_service() or
      EMPTY).id

  elseif conf.limit_by == "consumer" then
    identifier = (kong.client.get_consumer() or
      kong.client.get_credential() or
      EMPTY).id

  elseif conf.limit_by == "credential" then
    identifier = (kong.client.get_credential() or
      EMPTY).id

  elseif conf.limit_by == "header" then
    identifier = kong.request.get_header(conf.header_name)

  elseif conf.limit_by == "path" then
    local req_path = kong.request.get_path()
    if req_path == conf.path then
      identifier = req_path
    end
  end

  return identifier or kong.client.get_forwarded_ip()
end

function PreventReplyAttackHandler:access(conf)
  local identifier = get_identifier(conf)
  local key = kong.request.get_header(conf.key)
  local ttl = conf.ttl

  if not key then
    return kong.response.exit(400, "Bad request because of '" .. conf.key .. "' not exists")
  end

  local ok, err = policies[conf.policy].verify(conf, identifier, key, ttl)
  if err then
    kong.log.warn(err)
    return kong.response.error(403, "Access forbidden because of '" .. conf.key .. ":" .. key .. "' already used")
  end
end

return PreventReplyAttackHandler
