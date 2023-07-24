local skynet = require "skynet"
local socket = require "socket"
local proxy = require "socket_proxy"
local log = require "log"
local service = require "service"

local hub_copy = {}
local data = {}

local function connect_login_service(fd)
    log("enter connect_login_service")
    return (skynet.call(service.login_manager, "lua", "shakehand", fd))
end

local function assign_agent(fd, user_name)
    skynet.call(service.lobby, "lua", "new_user", fd, user_name)
end

function new_socket(fd, addr)
    log("start pcall connect_login_service")
    local ok, user_name = pcall(connect_login_service, fd)
    if ok then
        log("start pcall assign_agent")
        if pcall(assign_agent, fd, user_name) then
            return -- succ
        else
            log("Assign failed %s to %s", addr, user_name)
        end
    else
        log("Auth faild %s", addr)
    end
end

function hub_copy.open(ip, port)
    log("Listen %s:%d", ip, port)
    assert(data.fd == nil, "Already open")
    data.fd = socket.listen(ip, port)
    data.ip = ip
    data.port = port
    socket.start(data.fd, new_socket)
end

function hub_copy.close()
    assert(data.fd)
    log("Close %s:%d", data.ip, data.port)
    socket.close(data.fd)
    data.ip = nil
    data.port = nil
end

service.init {
    command = hub_copy,
    info = data,
    require = {"login_manager", "lobby"}
}
