local storage_module = require("utility.storage_module")

-- When recipes could have changed or when we are initialized, create our local storage
script.on_configuration_changed(function(event)
   storage_module.initialize()
end)

script.on_init(function()
   storage_module.initialize()
end)
