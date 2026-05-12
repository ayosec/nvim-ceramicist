local BLOB_PREFIX_URL = table.concat {
    "https://github.com/",
    os.getenv("GITHUB_REPOSITORY") or "example/repo",
    "/blob/main",
}

function Pandoc(d)
    local first = true
    return d:walk {
        Header = function(h)
            -- Insert TOC before the first header.
            if first then
                first = false
                return {
                    pandoc.RawBlock("html", [[
                        <nav id="my_toc">
                            <h2>Table Of Contents</h2>
                    ]]),
                    pandoc.structure.table_of_contents(d),
                    pandoc.RawBlock("html", "</nav>"),
                    h
                }
            else
                return h
            end
        end,

        Link = function(l)
            -- Replace relative links in the README to blob URLs
            -- in the GitHub repository.
            if string.sub(l.target, 1, 2) == "./" then
                l.target = BLOB_PREFIX_URL .. string.sub(l.target, 2)
            end
            return l
        end,
    }
end
