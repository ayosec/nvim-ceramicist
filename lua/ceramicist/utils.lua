local M = {}

--- @param mods vim.api.keyset.cmd.mods
--- @return "tab"|vim.api.keyset.win_config
--- @private
function M.parse_win_options(mods)
    if mods.tab ~= -1 then
        return "tab"
    end

    local vrt = mods.vertical

    --- @type vim.api.keyset.win_config
    local opts = { split = "below" }

    if vrt then
        opts.vertical = true
    end

    if mods.split == "botright" or mods.split == "belowright" or mods.split == "" then
        opts.split = vrt and "right" or "below"
    elseif mods.split == "aboveleft" or mods.split == "topleft" then
        opts.split = vrt and "left" or "above"
    end

    return opts
end


--- Escape the control characters in `str` to their equivalents
--- in `\xNN` format. Some characters (like `\n` or `\t`) are
--- translated to their single-letter form.
---
--- Return the escaped string, and the number of escaped chars.
---
--- @param str string
--- @return string, integer
function M.escape_control_chars(str)
    local tr = {
        ["\a"] = "\\a",
        ["\b"] = "\\b",
        ["\f"] = "\\f",
        ["\n"] = "\\n",
        ["\r"] = "\\r",
        ["\t"] = "\\t",
        ["\v"] = "\\v",
        ["\x1b"] = "\\e",
    }

    local function map(chr)
        return tr[chr] or string.format("\\x%02x", string.byte(chr))
    end

    return string.gsub(str, "%c", map)
end


--- Convert a duration in nanoseconds to an easier-to-read
--- representation. For example, `123456` returns `"123 μs"`.
---
--- @param nanos number
--- @return string
function M.format_duration(nanos)
    local scale = 1

    --- @param initscale integer
    --- @param base integer
    --- @param units string[]
    --- @return string|nil
    local function for_units(initscale, base, units)
        scale = scale * initscale
        for _, unit in ipairs(units) do
            local next_scale = scale * base
            if nanos < next_scale then
                return string.format("%d %s", math.floor(nanos / scale + 0.5), unit)
            end

            scale = next_scale
        end
    end

    return for_units(1, 1000, { "ns", "μs", "ms", "s" })
        or for_units(60 / 1000, 60, { "m", "h" })
        or string.format("%d d", math.floor(nanos / 8.64e13 + 0.5))
end


return M
