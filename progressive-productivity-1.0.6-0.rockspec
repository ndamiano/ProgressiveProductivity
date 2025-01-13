-- Suppress warnings for rockspec settings appearing as global variables to the language server
---@diagnostic disable: lowercase-global

rockspec_format = "3.0"
package = "progressive-productivity"
version = "1.0.6-0"
source = {
   url = "git+https://github.com/ndamiano/ProgressiveProductivity.git",
   tag = "v2.0.0"
}
description = {
   summary = "Progressive Productivity Factorio mod.",
   detailed = "As you craft things, you get better at crafting them",
   license = "MIT",
   homepage = "https://mods.factorio.com/mod/progressive-productivity",
   issues_url = "https://mods.factorio.com/mod/progressive-productivity/discussion",
   maintainer = "demonicpigg <https://mods.factorio.com/user/demonicpigg>",
   labels = { "factorio" }
}
dependencies = {
   "lua ~> 5.2",
   "luassert >= 1.9.0-1"
}
build = {
   type = "builtin",
   modules = {}
}
