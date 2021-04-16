local typedefs = require "kong.db.schema.typedefs"
local validate_header_name = require("kong.tools.utils").validate_header_name

local function validate_headers(pair)
  local old_header, new_header = pair:match("^([^:]+):*(.-)$")
  if validate_header_name(old_header) == nil then
    return nil, string.format("'%s' is not a valid header", tostring(old_header))
  end

  if validate_header_name(new_header) == nil then
    return nil, string.format("'%s' is not a valid header", tostring(new_header))
  end
  return true
end

local function validate_colon_headers(pair)
  return validate_headers(pair)
end

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
          { jwt_secret_key = { type = "string", default = "OCEANUM" }, },
          { jwt_secret_value = { type = "string", default = "secret" }, },
          {
            claims_to_header = {
              type = "array",
              required = true,
              elements = { type = "string", match = "^[^:]+:.*$", custom_validator = validate_colon_headers },
            },
          },
        },
      },
    },
  },
  entity_checks = {},
}
