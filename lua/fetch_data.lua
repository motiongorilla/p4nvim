local M = {}
local uv = vim.loop
M.user = ""
M.clientname = ""
M.clientroot = ""
M.clientstream = ""

function M.InitializeData()
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
                M.user = string.match(line, "User name:%s*(.*)")
            end
            if string.match(line, "Client name:") then
                M.clientname = string.match(line, "Client name:%s*(.*)")
            end
            if string.match(line, "Client root:") then
                M.clientroot = string.match(line, "Client root:%s*(.*)")
            end
            if string.match(line, "Client stream:") then
                M.clientstream = string.match(line, "Client stream:%s*(.*)")
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

function M.GetCLs()
    if not M.clientname then
        print("clientname is not provided")
        return
    end
    local cmd = string.format("p4 changelists -s pending -c %s", M.clientname)
    local handle = io.popen(cmd)
    local changelists = {"Create new CL"}

    if not handle then
        print("Failed to get CLs")
        return
    end
    local output = handle:read("*a")
    handle:close()

    -- process shell output to get CL numbers
    for line in output:gmatch("[^\r\n]+") do
        local cl, desc = line:match("^Change (%d+) .- '%s*(.-)%s*'$")
        if cl and desc then
            local full_info = "CL "..cl.." , Description: "..desc
            table.insert(changelists, full_info)
        end
    end
    return changelists
end

M.InitializeData()

return M
