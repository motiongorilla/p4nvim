local data = require("fetch_data")
local uv = vim.loop

function InitializeData()
    -- Shell commands
    local cmd = "p4"
    local cmd_args = {"info",}


    -- Setting pipe and arguments for shell process
    local stdio_pipe = uv.new_pipe()
    local options = {
        args = cmd_args,
        stdio = {nil, stdio_pipe, nil}
    }

    -- Init handle for result and making callback for execution end
    local handle
    local info = ""
    local on_exit = function(status)
        uv.read_stop(stdio_pipe)
        uv.close(stdio_pipe)
        uv.close(handle)

        -- Split the info into lines
        -- Set user data
        for line in info:gmatch("[^\r\n]+") do
            if string.match(line, "User name:") then
                data.user = string.match(line, "User name:%s*(.*)")
            end
            if string.match(line, "Client name:") then
                data.clientname = string.match(line, "Client name:%s*(.*)")
            end
            if string.match(line, "Client root:") then
                data.clientroot = string.match(line, "Client root:%s*(.*)")
            end
            if string.match(line, "Client stream:") then
                data.clientstream = string.match(line, "Client stream:%s*(.*)")
            end
        end
    end

    handle = uv.spawn(cmd, options, on_exit)

    uv.read_start(stdio_pipe, function(status, data)
        if data then
            info = info .. data
        end
    end)
end

InitializeData()
