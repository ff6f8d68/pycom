-- Enhanced plib/gui.lua for pycom with focus, scrollbars, resizable windows, popups

local gui = {}
local windows = {}
local focusedTextbox = nil
local popup = nil
local current_style = "normal"

-- Style presets
local styles = {
    normal = {
        border = {"+", "-", "|"},
        button = {prefix = "[", suffix = "]"},
        textbox = {bg = colors.black, fg = colors.white},
    },
    whiptail = {
        border = {"\194\172", "\226\128\148", "|"},
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

-- Create a new window
function gui.window(title, x, y, w, h, resizable)
    local win = {
        title = title, x = x, y = y, w = w, h = h,
        elements = {}, scroll = 0, resizable = resizable or false
    }

    function win.add_button(label, rx, ry, rw, rh, callback)
        table.insert(win.elements, {type = "button", label = label, x = rx, y = ry, w = rw, h = rh, callback = callback})
    end

    function win.add_textbox(var_name, rx, ry, width, text)
        table.insert(win.elements, {type = "textbox", x = rx, y = ry, w = width, var_name = var_name, value = text or ""})
    end

    function win.add_icon(rx, ry, img, fg, bg, callback)
        table.insert(win.elements, {type = "icon", x = rx, y = ry, image = img, fg = fg, bg = bg, callback = callback})
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

        -- Draw resize corner
        if win.resizable then
            term.setCursorPos(win.x + win.w - 1, win.y + win.h - 1)
            term.write("\226\149\135")
        end

        for _, el in ipairs(win.elements) do
            local abs_x = win.x + el.x
            local abs_y = win.y + el.y - win.scroll
            if el.type == "button" then
                term.setCursorPos(abs_x, abs_y)
                term.write(s.button.prefix .. el.label .. s.button.suffix)
            elseif el.type == "textbox" then
                term.setCursorPos(abs_x, abs_y)
                term.write(el.value .. string.rep(" ", el.w - #el.value))
            elseif el.type == "icon" then
                for dy, line in ipairs(el.image) do
                    term.setCursorPos(abs_x, abs_y + dy - 1)
                    term.blit(line, el.fg or line, el.bg or line)
                end
            end
        end
    end

    function win.handle_click(mx, my)
        for _, el in ipairs(win.elements) do
            local abs_x = win.x + el.x
            local abs_y = win.y + el.y - win.scroll
            if el.type == "button" and mx >= abs_x and mx <= abs_x + el.w and my >= abs_y and my <= abs_y + el.h then
                el.callback()
            elseif el.type == "textbox" and mx >= abs_x and mx <= abs_x + el.w and my == abs_y then
                focusedTextbox = el
            elseif el.type == "icon" and el.callback then
                if mx >= abs_x and mx <= abs_x + #el.image[1] and my >= abs_y and my <= abs_y + #el.image then
                    el.callback()
                end
            end
        end
    end

    table.insert(windows, win)
    return win
end

-- Popups
function gui.popup(title, w, h)
    popup = gui.window(title, math.floor((term.getSize()) / 2 - w / 2), 3, w, h)
    popup.is_popup = true
    return popup
end

-- Redraw
function gui.redraw()
    term.clear()
    for _, win in ipairs(windows) do
        if not win.is_popup then win.draw() end
    end
    if popup then popup.draw() end
end

-- Main loop
function gui.run()
    gui.redraw()
    while true do
        local e, p1, p2, p3 = os.pullEvent()
        if e == "mouse_click" then
            local mx, my = p2, p3
            if popup then
                popup.handle_click(mx, my)
            else
                for _, win in ipairs(windows) do
                    win.handle_click(mx, my)
                end
            end
        elseif e == "char" and focusedTextbox then
            focusedTextbox.value = focusedTextbox.value .. p1
        elseif e == "key" and focusedTextbox then
            if p1 == keys.backspace then
                focusedTextbox.value = focusedTextbox.value:sub(1, -2)
            end
        end
        gui.redraw()
    end
end

return gui
