local gui = {}
local windows = {}

function gui.window(title, x, y, w, h)
    local win = {
        title = title,
        x = x,
        y = y,
        w = w,
        h = h,
        elements = {}
    }

    function win.add_button(label, bx, by, bw, bh, callback)
        table.insert(win.elements, {
            type = "button",
            label = label,
            x = bx,
            y = by,
            w = bw,
            h = bh,
            callback = callback
        })
    end

    function win.draw()
        term.setCursorPos(win.x, win.y)
        term.write("+" .. string.rep("-", win.w - 2) .. "+")
        for i = 1, win.h - 2 do
            term.setCursorPos(win.x, win.y + i)
            term.write("|" .. string.rep(" ", win.w - 2) .. "|")
        end
        term.setCursorPos(win.x, win.y + win.h - 1)
        term.write("+" .. string.rep("-", win.w - 2) .. "+")

        for _, el in ipairs(win.elements) do
            if el.type == "button" then
                term.setCursorPos(win.x + el.x, win.y + el.y)
                term.write("[" .. el.label .. "]")
            end
        end
    end

    table.insert(windows, win)
    return win
end

function gui.run()
    for _, win in ipairs(windows) do
        win.draw()
    end

    while true do
        local e, btn, mx, my = os.pullEvent("mouse_click")
        for _, win in ipairs(windows) do
            for _, el in ipairs(win.elements) do
                if el.type == "button" then
                    local bx = win.x + el.x
                    local by = win.y + el.y
                    if mx >= bx and mx <= bx + el.w and my >= by and my <= by + el.h then
                        el.callback()
                    end
                end
            end
        end
    end
end

return gui
