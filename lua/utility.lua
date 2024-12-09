local M = {}

function M.countKeys(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function M.execute_command(command, file, cl)
    local cmd = "p4 "..command
    if cl then
        cmd = "p4 "..command.." -c "..cl.." "..file
    elseif file then
        cmd = "p4 "..command.." "..file
    end
    vim.cmd("!" .. cmd)
end

function M.get_file()
    local filepath = vim.api.nvim_buf_get_name(0)
    if filepath == "" then
        print("Failed to get file path from current buffer.")
        return
    end
    return filepath
end

function M.create_window(width, height, lines)
    -- Create a new buffer and window for displaying changelists
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

    -- Define window options
    local opts = {
        relative = "editor",
        width = width,
        height = math.min(height, 10), -- Limit height to avoid overly large windows
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        style = "minimal",
        border = "single",
    }

    local window = vim.api.nvim_open_win(buffer, true, opts)
    return buffer, window
end

return M
