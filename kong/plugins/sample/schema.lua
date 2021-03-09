local typedefs = require "kong.db.schema.typedefs"

return {
  name = "sample",
  fields = {
    {
      -- this plugin will only be applied to Services or Routes
      consumer = typedefs.no_consumer
    },
    {
      -- this plugin will only run within Nginx HTTP module
      protocols = typedefs.protocols_http
    },
    {
      config = {
        type = "record",
        -- Describe your plugin's configuration's schema here.
        fields = {
          {
            anonymous = {
              type = "string",
              required = false,
            },
          },
          {
            verify = {
              type = "boolean",
              default = false,
            },
          },
          {
            auth_key = {
              type = "string",
              required = true,
              default = {
                "apikey"
              },
              elements = typedefs.header_name,
            }
          },
          {
            env = {
              type = "string",
              required = true,
              one_of = {
                "production",
                "development",
              },
            },
          },
          {
            server = {
              type = "record",
              fields = {
                {
                  host = typedefs.host {
                    default = "example.com",
                  },
                },
                {
                  port = {
                    type = "number",
                    default = 80,
                    between = {
                      0,
                      65534
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
  entity_checks = {-- Describe your plugin's entity validation rules
  },
}
