local skynet = require "skynet"

skynet.start(function()
	skynet.error("Server start")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	local proto = skynet.uniqueservice "protoloader"
	skynet.call(proto, "lua", "load", {
		"proto.c2s",
		"proto.s2c",
	})
	local hub_copy = skynet.uniqueservice "hub_copy"
	skynet.call(hub_copy, "lua", "open", "0.0.0.0", 5678)
	skynet.exit()
end)
