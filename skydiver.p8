pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

game_state = {
    splash = 0,
    playing = 1,
    fail = 2,
    landed = 3
}

crows = {}
crow_size = 3 -- width and height of a crow
crow_pixel_size = crow_size - 1 -- crow right/bottom pixel, for use in rect funtion (annoying that it's not just crow_size)
diver_size = 1 -- width and height of the diver (if using pset)

-- returns true if two rectangles overlap at all
-- x1, y1, w1, h1 are the first rectangle's top left x, top left y, width, and height
-- x2, y2, w2, h2 are the second rectangle's top left x, top left y, width, and height
function check_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

-- prints text centered horizontally
function print_centered(text, y, color)
    local x = (128 - #text * 4) / 2
    print(text, x, y, color)
end

function clear_table(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

function reset()
    diver_x = flr(rnd()*128)
    diver_y = 0
    target = flr(rnd()*120)
    clear_table(crows)
    for i = 1, 50 do
        add(crows, 
        {
            x = flr(rnd()*128), 
            y = 14 + flr(rnd()*100) -- this avoids crows in the top 14 pixels and bottom 14 pixels
        })
    end
    current_state = game_state.playing
end

function _init()
    current_state = game_state.splash
end

function _update()
    if current_state ~= game_state.playing then
        if btn(4) then
            reset()
        end
        return
    end

    diver_y += 1
	if btn(0) then diver_x -= 1 end
	if btn(1) then diver_x += 1 end
    
    if diver_y >= 127 then
        if diver_x < target or diver_x > target + 8 then
            current_state = game_state.fail
        else
            current_state = game_state.landed
        end
        diver_y = 127
    end

    for crow in all(crows) do
        if check_collision(diver_x, 
                           diver_y, 
                           diver_size, 
                           diver_size, 
                           crow.x, 
                           crow.y, 
                           crow_size, 
                           crow_size) then
            current_state = game_state.fail
        end
    end
end

function _draw()
	cls()
    if current_state == game_state.splash then
        print_centered("skydiver!", 30, 7)
        print_centered("n: new game", 50, 7)
        print_centered("move left and right", 70, 7)
        print_centered("to hit the target!", 80, 7)
        print_centered("avoid the crows!", 100, 7)
        return
    else
        rect(target, 127, target + 8, 127, 7)
        for crow in all(crows) do
            rect(crow.x, crow.y, crow.x + crow_pixel_size, crow.y + crow_pixel_size, 1)
        end
        if current_state == game_state.fail then
            print_centered("too bad", 64, 8)
        elseif current_state == game_state.landed then
            print_centered("landed", 64, 8)
        end
    	pset(diver_x, diver_y, 8)
    end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
