package = "kong-plugin-prevent-reply-attack"
version = "0.1.0-1"

local pluginName = package:match("^kong%-plugin%-(.+)$")

supported_platforms = {"linux", "macosx"}
source = {
  url = "https://192.168.10.123:8089/platform.ocp/kong-plugin.git",
  tag = "0.1.0"
}

description = {
  summary = "Extended official jwt plugin used to compatible with old API",
  license = "Apache 2.0"
}

dependencies = {
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
    ["kong.plugins."..pluginName..".policies.init"] = "kong/plugins/"..pluginName.."/policies/init.lua",
  }
}
