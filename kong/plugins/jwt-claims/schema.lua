local typedefs = require "kong.db.schema.typedefs"

return {
  name = "jwt-claims",
  fields = {
    { protocols = typedefs.protocols_http },
    {
      config = {
        type = "record",
        fields = {
          {
            header_names = {
              type = "set",
              elements = { type = "string" },
              default = { "token" },
            },
          },
          { jwt_consumer_id = { type = "string", default = "businessNo", } },
          { jwt_secret_key = { type = "string", default = "OCEANUM" }, },
          { jwt_secret_value = { type = "string", default = "secret" }, },
        },
      },
    },
  },
  entity_checks = {},
}
