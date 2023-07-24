local skynet = require "skynet"
local socket = require "socket"
local proxy = require "socket_proxy"
local log = require "log"
local service = require "service"

local hub = {}
local data = {
    socket = {}
}

local function auth_socket(fd)
    log("enter auth_socket")
    --return (skynet.call(service.auth, "lua", "shakehand", fd))
    return (skynet.call(service.auth, "lua", "test_shakehand", fd))
end

local function assign_agent(fd, userid)
    skynet.call(service.manager, "lua", "assign", fd, userid)
end

function new_socket(fd, addr)
    data.socket[fd] = "[AUTH]"
    log("enter new_socket and proxy.subscribe fd %s", fd)
    --proxy.subscribe(fd)
    log("start pcall auth_socket")
    local ok, userid = pcall(auth_socket, fd)
    if ok then
        data.socket[fd] = userid
        if pcall(assign_agent, fd, userid) then
            return -- succ
        else
            log("Assign failed %s to %s", addr, userid)
        end
    else
        log("Auth faild %s", addr)
    end
    proxy.close(fd)
    data.socket[fd] = nil
end

function test_new_socket(fd, addr)
    log("trigger test_new_socket fffffffffff")
    skynet.call(service.auth, "lua", "test_shakehand", fd)
end

function hub.open(ip, port)
    log("Listen %s:%d", ip, port)
    assert(data.fd == nil, "Already open")
    data.fd = socket.listen(ip, port)
    data.ip = ip
    data.port = port
    log("hub.open listen fd is %s", data.fd)
    --socket.start(data.fd, new_socket)
    socket.start(data.fd, test_new_socket)
end

function hub.close()
    assert(data.fd)
    log("Close %s:%d", data.ip, data.port)
    socket.close(data.fd)
    data.ip = nil
    data.port = nil
end

service.init {
    command = hub,
    info = data,
    require = {"auth", "manager"}
}
