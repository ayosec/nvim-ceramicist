local signals = {}
for name, num in pairs(vim.loop.constants) do
    if vim.startswith(name, "SIG") then
        signals[num] = name
    end
end

return signals
