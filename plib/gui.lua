local gui = {}

-- State
local windows = {}
local current_style = "normal"

-- Styles
local styles = {
    normal = {
        border = {"+", "-", "|"},
        button = {prefix = "[", suffix = "]"},
        textbox = {bg = colors.black, fg = colors.white},
    },
    whiptail = {
        border = {"┌", "─", "│"},
        button = {prefix = "<", suffix = ">"},
        textbox = {bg = colors.blue, fg = colors.white},
    }
}

function gui.set_style(name)
    if styles[name] then
        current_style = name
    else
        error("Unknown style: " .. name)
    end
end

-- Window
function gui.window(title, x, y, w, h)
    local win = {
        title = title,
        x = x, y = y,
        w = w, h = h,
        elements = {}
    }

    function win.add_button(label, rx, ry, rw, rh, callback)
        table.insert(win.elements, {
            type = "button", label = label,
            x = rx, y = ry, w = rw, h = rh,
            callback = callback
        })
    end

    function win.add_textbox(var_name, rx, ry, width, text)
        table.insert(win.elements, {
            type = "textbox",
            x = rx, y = ry, w = width,
            var_name = var_name,
            value = text or ""
        })
    end

    function win.add_icon(rx, ry, image_data, callback)
        table.insert(win.elements, {
            type = "icon", x = rx, y = ry,
            image = image_data, callback = callback
        })
    end

    function win.add_list(rx, ry, items, callback)
        table.insert(win.elements, {
            type = "list", x = rx, y = ry,
            items = items, callback = callback
        })
    end

    function win.add_icon_list(rx, ry, items, callback)
        table.insert(win.elements, {
            type = "icon_list", x = rx, y = ry,
            items = items, callback = callback
        })
    end

    function win.draw()
        local s = styles[current_style]
        term.setCursorPos(win.x, win.y)
        term.write(s.border[1] .. string.rep(s.border[2], win.w - 2) .. s.border[1])
        for i = 1, win.h - 2 do
            term.setCursorPos(win.x, win.y + i)
            term.write(s.border[3] .. string.rep(" ", win.w - 2) .. s.border[3])
        end
        term.setCursorPos(win.x, win.y + win.h - 1)
        term.write(s.border[1] .. string.rep(s.border[2], win.w - 2) .. s.border[1])

        for _, el in ipairs(win.elements) do
            local abs_x = win.x + el.x
            local abs_y = win.y + el.y
            if el.type == "button" then
                term.setCursorPos(abs_x, abs_y)
                term.write(s.button.prefix .. el.label .. s.button.suffix)
            elseif el.type == "textbox" then
                term.setCursorPos(abs_x, abs_y)
                term.write(el.value .. string.rep(" ", el.w - #el.value))
            elseif el.type == "icon" then
                for dy, line in ipairs(el.image) do
                    term.setCursorPos(abs_x, abs_y + dy - 1)
                    term.write(line)
                end
            elseif el.type == "list" then
                for i, item in ipairs(el.items) do
                    term.setCursorPos(abs_x, abs_y + i - 1)
                    term.write("• " .. item)
                end
            elseif el.type == "icon_list" then
                for i, icon in ipairs(el.items) do
                    term.setCursorPos(abs_x, abs_y + (i - 1) * 2)
                    term.write("[" .. icon.icon .. "] " .. icon.label)
                end
            end
        end
    end

    function win.handle_click(mx, my)
        for _, el in ipairs(win.elements) do
            local abs_x = win.x + el.x
            local abs_y = win.y + el.y

            if el.type == "button" and
                mx >= abs_x and mx <= abs_x + el.w and
                my >= abs_y and my <= abs_y + el.h then
                el.callback()
            elseif el.type == "icon" and el.callback then
                if mx >= abs_x and mx <= abs_x + #el.image[1] and
                   my >= abs_y and my <= abs_y + #el.image then
                    el.callback()
                end
            elseif el.type == "list" or el.type == "icon_list" then
                for i, item in ipairs(el.items) do
                    local iy = abs_y + (el.type == "icon_list" and (i - 1) * 2 or i - 1)
                    if mx >= abs_x and mx <= abs_x + 20 and my == iy then
                        if el.callback then el.callback(item, i) end
                    end
                end
            end
        end
    end

    table.insert(windows, win)
    return win
end

-- Redraw everything
function gui.redraw()
    term.clear()
    for _, win in ipairs(windows) do
        win.draw()
    end
end

function gui.run()
    gui.redraw()

    while true do
        local e, btn, x, y = os.pullEvent()
        if e == "mouse_click" then
            for _, win in ipairs(windows) do
                win.handle_click(x, y)
            end
        elseif e == "char" then
            -- You can expand this to feed input into focused textboxes
        end

        gui.redraw()
    end
end

return gui
