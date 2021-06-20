local BasePlugin = require "kong.plugins.base_plugin"
local constants = require "kong.constants"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local JwtClaimsHandler = BasePlugin:extend()

JwtClaimsHandler.VERSION = "0.1.0"
JwtClaimsHandler.PRIORITY = 1005

local function set_consumer(consumer, credential)
  kong.client.authenticate(consumer, credential)

  local set_header = kong.service.request.set_header
  local clear_header = kong.service.request.clear_header

  if consumer and consumer.id then
    set_header(constants.HEADERS.CONSUMER_ID, consumer.id)
  else
    clear_header(constants.HEADERS.CONSUMER_ID)
  end

  if consumer and consumer.custom_id then
    set_header(constants.HEADERS.CONSUMER_CUSTOM_ID, consumer.custom_id)
  else
    clear_header(constants.HEADERS.CONSUMER_CUSTOM_ID)
  end

  if consumer and consumer.username then
    set_header(constants.HEADERS.CONSUMER_USERNAME, consumer.username)
  else
    clear_header(constants.HEADERS.CONSUMER_USERNAME)
  end

  if credential and credential.key then
    set_header(constants.HEADERS.CREDENTIAL_IDENTIFIER, credential.key)
  else
    clear_header(constants.HEADERS.CREDENTIAL_IDENTIFIER)
  end

  clear_header(constants.HEADERS.CREDENTIAL_USERNAME)

  if credential then
    clear_header(constants.HEADERS.ANONYMOUS)
  else
    set_header(constants.HEADERS.ANONYMOUS, true)
  end
end

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

  -- Retrieve the consumer
  local consumer_id = claims[conf.jwt_consumer_id]
  if not consumer_id then
    return false, { status = 401, message = "Invalid consumer id config" }
  end

  local consumer_cache_key = kong.db.consumers:cache_key(consumer_id)
  local consumer, err      = kong.cache:get(consumer_cache_key, nil, kong.client.load_consumer, consumer_id, true)

  if err then
    return error(err)
  end

  set_consumer(consumer)

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
