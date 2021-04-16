Kong plugin template
====================

This repository contains a very simple Kong plugin template to get you
up and running quickly for developing your own plugins.

This template was designed to work with the
[`kong-pongo`](https://github.com/Kong/kong-pongo) and
[`kong-vagrant`](https://github.com/Kong/kong-vagrant) development environments.

Please check out those repos `README` files for usage instructions.

[badge-travis-url]: https://travis-ci.org/Kong/kong-plugin/branches
[badge-travis-image]: https://travis-ci.com/Kong/kong-plugin.svg?branch=master

## Installing your plugin

### Introduction

Custom plugins for Kong consist of Lua source files that need to be in the file system
of each of your Kong nodes. This guide will provide you with step-by-step instructions
that will make a Kong node aware of your custom plugin(s).

These steps should be applied to each node in your Kong cluster, to ensure the custom
plugin(s) are available on each one of them.

### Packaging sources

You can either use a regular packing strategy (e.g. tar), or use the LuaRocks package
manager to do it for you. We recommend LuaRocks as it is installed along with Kong
when using one of the official distribution packages.

When using LuaRocks, you must create a rockspec file, which specifies the package
contents. For an example see the Kong plugin template, for more info about the format
see the LuaRocks documentation on rockspecs.

Pack your rock using the following command (from the plugin repo):

```bash
# install it locally (based on the `.rockspec` in the current directory)
$ luarocks make <<plugin-name>-<version>.rockspec

# pack the installed rock
$ luarocks pack <plugin-name> <version>
```

Assuming your plugin rockspec is called kong-plugin-my-plugin-0.1.0-1.rockspec,
the above would become;

```bash
$ luarocks pack kong-plugin-my-plugin 0.1.0-1
```

The LuaRocks pack command has now created a .rock file (this is simply a zip file
containing everything needed to install the rock).

If you do not or cannot use LuaRocks, then use tar to pack the .lua files of which
your plugin consists into a .tar.gz archive. You can also include the .rockspec
file if you do have LuaRocks on the target systems.

The contents of this archive should be close to the following:

```bash
$ tree <plugin-name>
<plugin-name>
├── INSTALL.txt
├── README.md
├── kong
│   └── plugins
│       └── <plugin-name>
│           ├── handler.lua
│           └── schema.lua
└── <plugin-name>-<version>.rockspec
```

### Installing the plugin

For a Kong node to be able to use the custom plugin, the custom plugin’s Lua sources
must be installed on your host’s file system. There are multiple ways of doing so:
via LuaRocks, or manually. Choose one, and jump to section 3.

**1. Via LuaRocks from the created ‘rock’**

The .rock file is a self contained package that can be installed locally or
from a remote server.

If the luarocks utility is installed in your system (this is likely the case
if you used one of the official installation packages), you can install the ‘rock’
in your LuaRocks tree (a directory in which LuaRocks installs Lua modules).

It can be installed by doing:

```bash
$ luarocks install <rock-filename>
```

The filename can be a local name, or any of the supported methods,
eg. http://myrepository.lan/rocks/my-plugin-0.1.0-1.all.rock

**2. Via LuaRocks from the source archive**

If the luarocks utility is installed in your system (this is likely the case if you
used one of the official installation packages), you can install the Lua sources in
your LuaRocks tree (a directory in which LuaRocks installs Lua modules).

You can do so by changing the current directory to the extracted archive, where the
rockspec file is:

```bash
$ cd <plugin-name>
```

And then run the following:

```bash
$ luarocks make
```

This will install the Lua sources in kong/plugins/<plugin-name> in your system’s
LuaRocks tree, where all the Kong sources are already present.

**3. Manually**

A more conservative way of installing your plugin’s sources is to avoid “polluting”
the LuaRocks tree, and instead, point Kong to the directory containing them.

This is done by tweaking the lua_package_path property of your Kong configuration.
Under the hood, this property is an alias to the LUA_PATH variable of the Lua VM,
if you are familiar with it.

Those properties contain a semicolon-separated list of directories in which to
search for Lua sources. It should be set like so in your Kong configuration file:

```bash
lua_package_path = /<path-to-plugin-location>/?.lua;;
```

Where:

- `/<path-to-plugin-location>` is the path to the directory containing the
  extracted archive. It should be the location of the `kong` directory from the archive.
- `?` is a placeholder that will be replaced by `kong.plugins.<plugin-name>` when Kong
  will try to load your plugin. Do not change it.
  `;;` a placeholder for the "the default Lua path". Do not change it.

Example:

The plugin something being located on the file system such that the handler file is:

```bash
/usr/local/custom/kong/plugins/<something>/handler.lua
```

The location of the kong directory is: /usr/local/custom, hence the proper path setup would be:

```bash
lua_package_path = /usr/local/custom/?.lua;;
```

Multiple plugins:

If you wish to install two or more custom plugins this way, you can set the variable to something like:

```bash
lua_package_path = /path/to/plugin1/?.lua;/path/to/plugin2/?.lua;;
```

- ; is the separator between directories.
- ;; still means “the default Lua path”.

**Note**: you can also set this property via its environment variable equivalent: KONG_LUA_PACKAGE_PATH.

Reminder: regardless of which method you are using to install your plugin’s sources,
you must still do so for each node in your Kong cluster.

## Load the plugin

You must now add the custom plugin’s name to the plugins list in your Kong configuration (on each Kong node):

```bash
plugins = bundled,<plugin-name>
```

Or, if you don’t want to include the bundled plugins:

```bash
plugins = <plugin-name>
```

If you are using two or more custom plugins, insert commas in between, like so:

```bash
plugins = bundled,plugin1,plugin2
```

Or

```bash
plugins = plugin1,plugin2
```

**Note**: you can also set this property via its environment variable equivalent: KONG_PLUGINS.
Reminder: don’t forget to update the plugins directive for each node in your Kong cluster.

Reminder: the plugin will take effect after restart kong:

```bash
kong restart
```

But, if you want to apply plugin while kong never stop, you can use this:

```bash
kong prepare
kong reload
```

## Verify loading the plugin

You should now be able to start Kong without any issue. Consult your custom plugin’s
instructions on how to enable/configure your plugin on a Service, Route, or Consumer entity.

To make sure your plugin is being loaded by Kong, you can start Kong with a debug log level:

```bash
log_level = debug
```

or

```bash
KONG_LOG_LEVEL=debug
```

Then, you should see the following log for each plugin being loaded:

```bash
[debug] Loading plugin <plugin-name>
```

## Removing a plugin

There are three steps to completely remove a plugin.

- Remove the plugin from your Kong Service or Route configuration. Make sure that it is no longer
  applied globally nor for any Service, Route, or consumer. This has to be done only once for the
  entire Kong cluster, no restart/reload required. This step in itself will make that the plugin
  is no longer in use. But it remains available and it is still possible to re-apply the plugin.

- Remove the plugin from the plugins directive (on each Kong node). Make sure to have completed
  step 1 before doing so. After this step it will be impossible for anyone to re-apply the plugin
  to any Kong Service, Route, Consumer, or even globally. This step requires to restart/reload the
  Kong node to take effect.

- To remove the plugin thoroughly, delete the plugin-related files from each of the Kong nodes.
  Make sure to have completed step 2, including restarting/reloading Kong, before deleting the files.
  If you used LuaRocks to install the plugin, you can do luarocks remove <plugin-name> to remove it.

## Troubleshooting

Kong can fail to start because of a misconfigured custom plugin for several reasons:

- "plugin is in use but not enabled" -> You configured a custom plugin from another node, and that
  the plugin configuration is in the database, but the current node you are trying to start does not
  have it in its plugins directive. To resolve, add the plugin’s name to the node’s plugins directive.

- "plugin is enabled but not installed" -> The plugin’s name is present in the plugins directive,
  but that Kong is unable to load the handler.lua source file from the file system. To resolve,
  make sure that the lua_package_path directive is properly set to load this plugin’s Lua sources.

- "no configuration schema found for plugin" -> The plugin is installed, enabled in the plugins directive,
  but Kong is unable to load the schema.lua source file from the file system. To resolve, make sure that
  the schema.lua file is present alongside the plugin’s handler.lua file.



