local M = {}

function M.defaults()
    --- @class ceramicist.Config
    local config = {
        --- Name of the user command to open execute a job.
        ---
        --- If `nil`, no command will be created.
        ---
        --- @type string|nil
        user_command = "Ceramicist",

        --- Status line for Ceramicist windows.
        ---
        --- Set to `false` to keep the global status line.
        ---
        --- @type string|false
        statusline = table.concat {
            [[%{%exists('b:ceramicist_statusline') ? b:ceramicist_statusline() : '%t'%}]],
            [[%=%-15(%l,%c%V%) %P]]
        },

        --- Command to spawn a job from a `cmdline`.
        ---
        --- @param cmdline string
        --- @return string[]
        job_command = function(cmdline)
            return { vim.o.shell, vim.o.shellcmdflag, cmdline }
        end,

        --- Prefix for highlight groups.
        highlight_name_prefix = "Ceramicist",

        output = {
            --- Number of empty lines to add before adding new jobs
            --- to an existing session.
            ---
            --- @type integer
            gap = 2,

            --- Number of empty lines to add after the header and
            --- before the footer.
            ---
            --- @type integer
            padding = 1,

            --- Contents of the line written when a job is started.
            ---
            --- It receives the command line to be executed, and
            --- returns a list to be used as the `virt_text` field
            --- for `nvim_buf_set_extmark`.
            ---
            --- @param cmdline string
            header = function(cmdline)
                return {
                    { require("ceramicist.utils").escape_control_chars(cmdline), "" }
                }
            end,

            --- Contents of the line written when a job is finished.
            ---
            --- Like `header`, it returns the value for `virt_text`.
            ---
            --- @param exit integer|string Exit code or signal name.
            --- @param duration integer Duration in nanoseconds.
            footer = function(exit, duration)
                local fd = require("ceramicist.utils").format_duration(duration)
                return {
                    { "Exit code " .. exit .. " after " .. fd, "" }
                }
            end,
        }
    }

    return config
end

return M
