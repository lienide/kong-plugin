local typedefs = require "kong.db.schema.typedefs"

return {
  name = "prevent-reply-attack",
  fields = {
    {
      protocols = typedefs.protocols_http
    },
    {
      config = {
        type = "record",
        fields = {
          { key = { type = "string", default = "nonce", } },
          { ttl = { type = "number", default = 60, }, },
          { sign = {
            type = "string",
            default = "consumer",
            one_of = { "consumer", "credential", "ip", "service", "header", "path" },
          }, },
          { policy = {
            type = "string",
            default = "redis",
            len_min = 0,
            one_of = { "redis" },
          }, },
          { redis_host = typedefs.host },
          { redis_port = typedefs.port({ default = 6379 }), },
          { redis_password = { type = "string", len_min = 0, }, },
          { redis_timeout = { type = "number", default = 2000, }, },
          { redis_database = { type = "integer", default = 0, }, },
        },
      },
    },
  },
  entity_checks = {
    { conditional = {
      if_field = "config.policy", if_match = { eq = "redis" },
      then_field = "config.redis_host", then_match = { required = true },
    } },
    { conditional = {
      if_field = "config.policy", if_match = { eq = "redis" },
      then_field = "config.redis_port", then_match = { required = true },
    } },
    { conditional = {
      if_field = "config.policy", if_match = { eq = "redis" },
      then_field = "config.redis_timeout", then_match = { required = true },
    } },
  },
}
