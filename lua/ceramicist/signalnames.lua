local signals = {}
for name, num in pairs(vim.uv.constants) do
    if vim.startswith(name, "SIG") then
        signals[num] = name
    end
end

return signals
