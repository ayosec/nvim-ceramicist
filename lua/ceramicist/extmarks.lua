local M = {}

local EXTMARK_NS = vim.api.nvim_create_namespace("ceramicist.extmarks")

--- OSC sequence to add extmarks.
local OSC_EXTMARK = "\x1b]9999;ceramicist.extmark;"

--- Return a function to add extmarks to {session}.
---
--- Nvim 0.12 does not provide an API to get the cursor position (issue 26600),
--- but it is available in |TermRequest| autocommands. In order to add extmarks
--- at the correct line, a custom OSC is written with a reference to the new
--- extmark, which is then captured in an autocommand.
---
--- @param session ceramicist.Session
function M.extmark_handler(session)
    local next_id = 1

    --- @type { [integer]: vim.api.keyset.set_extmark }
    local pending_extmarks = {}

    -- Process the custom OSC.
    vim.api.nvim_create_autocmd("TermRequest", {
        buffer = session.buffer,
        callback = function(ev)
            local extmark_id, subs = string.gsub(ev.data.sequence, OSC_EXTMARK, "", 1)
            if subs ~= 1 then return end

            local key = tonumber(extmark_id)
            local extmark = pending_extmarks[key]

            if key and extmark then
                local line = ev.data.cursor[1] - 1
                pcall(vim.api.nvim_buf_set_extmark, ev.buf, EXTMARK_NS, line, 0, extmark)
                pending_extmarks[key] = nil
            end
        end,
    })

    --- @param extmark vim.api.keyset.set_extmark
    local function add_extmark(extmark)
        if session.term_channel_id == nil then return end

        local extmark_id = next_id
        next_id = next_id + 1

        pending_extmarks[extmark_id] = extmark

        vim.api.nvim_chan_send(
            session.term_channel_id,
            OSC_EXTMARK .. extmark_id .."\x07"
        )
    end

    return add_extmark
end

return M
