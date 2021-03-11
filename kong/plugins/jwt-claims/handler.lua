local BasePlugin = require "kong.plugins.base_plugin"
local constants = require "kong.constants"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local JwtClaimsHandler = BasePlugin:extend()

JwtClaimsHandler.VERSION = "1.0.0"
JwtClaimsHandler.PRIORITY = 999

local function retrieve_token(conf)
  local request_headers = kong.request.get_headers()
  for _, v in ipairs(conf.header_names) do
    if request_headers[v] then
      return request_headers[v]
    end
  end
end

local function do_authentication(conf)
  local token = retrieve_token(conf)
  if not token then
    return kong.response.exit(401, "Unrecognizable token")
  end

  local token_type = type(token)
  if token_type ~= "string" then
    if token_type == "nil" then
      return false, { status = 401, message = "Unauthorized" }
    elseif token_type == "table" then
      return false, { status = 401, message = "Multiple tokens provided" }
    else
      return false, { status = 401, message = "Unrecognizable token" }
    end
  end

  -- Decode token to find out who the consumer is
  local jwt, err = jwt_decoder:new(token)
  if err then
    return false, { status = 401, message = "Bad token; " .. tostring(err) }
  end

  local claims = jwt.claims
  local header = jwt.header

  local key = conf.jwt_secret_key
  local secret = conf.jwt_secret_value

  local issuer = "iss"
  local algorithm = "HS256"

  -- Verify "alg"
  if header.alg ~= algorithm then
    return false, { status = 401, message = "Invalid algorithm" }
  end

  -- Verify "iss"
  if claims[issuer] ~= key then
    return false, { status = 401, message = "Invalid issuer" }
  end

  -- Verify "secret"
  if not jwt:verify_signature(secret) then
    return false, { status = 401, message = "Invalid signature" }
  end

  local set_header = kong.service.request.set_header
  for _, pair in ipairs(conf.claims_to_header) do
    local old_header, new_header = pair:match("^([^:]+):*(.-)$")
    local v = claims[old_header]
    if v then
      set_header(new_header, v)
    end
  end

  return true
end

function JwtClaimsHandler:new()
  JwtClaimsHandler.super.new(self, "jwt-claims")
end

function JwtClaimsHandler:access(conf)

  local ok, err = do_authentication(conf)
  if not ok then
    return kong.response.exit(err.status, err.errors or { message = err.message })
  end
end

return JwtClaimsHandler
