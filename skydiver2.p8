pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

game_state = {
    splash = 0,
    playing = 1,
    fail = 2,
    landed = 3
}

direction = {
    vertical = 0,
    left = 1,
    right = 2
}

local diver_size = 16 -- width and height of the diver 
local target_width = 8 -- width of the target

local crow_frames = {6, 7, 8, 9, 10, 11, 12, 11, 10, 9, 8, 7}
local crows = {}

-- returns true if two rectangles overlap at all
-- x1, y1, w1, h1 are the first rectangle's top left x, top left y, width, and height
-- x2, y2, w2, h2 are the second rectangle's top left x, top left y, width, and height
function check_box_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

-- Check pixel-perfect collision between two sprites
function check_pixel_collision(x1, y1, w1, h1, sprite1, flip_x1, flip_y1, x2, y2, w2, h2, sprite2, flip_x2, flip_y2)
    -- Get the overlapping area
    local x_start = max(x1, x2)
    local y_start = max(y1, y2)
    local x_end = min(x1 + w1, x2 + w2)
    local y_end = min(y1 + h1, y2 + h2)

    -- Check each pixel in the overlapping area
    for x = x_start, x_end - 1 do
        for y = y_start, y_end - 1 do
            -- Calculate the relative positions of the pixels in the sprites
            local rel_x1 = flip_x1 and w1 - 1 - (x - x1) or x - x1
            local rel_y1 = flip_y1 and h1 - 1 - (y - y1) or y - y1
            local rel_x2 = flip_x2 and w2 - 1 - (x - x2) or x - x2
            local rel_y2 = flip_y2 and h2 - 1 - (y - y2) or y - y2

            -- Calculate the pixel coordinates in the sprite sheet
            local sprite_x1 = sprite1 % 16 * 8 + rel_x1
            local sprite_y1 = flr(sprite1 / 16) * 8 + rel_y1
            local sprite_x2 = sprite2 % 16 * 8 + rel_x2
            local sprite_y2 = flr(sprite2 / 16) * 8 + rel_y2

            -- Get the colors of the pixels in the two sprites
            local color1 = sget(sprite_x1, sprite_y1)
            local color2 = sget(sprite_x2, sprite_y2)

            -- If both pixels are not transparent, there is a collision
            if color1 != 0 and color2 != 0 then
                return true
            end
        end
    end

    -- No collision
    return false
end

function check_collision(x1, y1, w1, h1, sprite1, flip_x1, flip_y1, x2, y2, w2, h2, sprite2, flip_x2, flip_y2)
    -- Check if the bounding boxes overlap

    local only_check_bounding_boxes = false
    if only_check_bounding_boxes then
        return check_box_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    end

    if not check_box_collision(x1, y1, w1, h1, x2, y2, w2, h2) then
        return false
    end

    if not check_box_collision(x1, y1, w1, h1, x2, y2, w2, h2) then
        return false
    end

    -- Check if any pixels overlap
    return check_pixel_collision(x1, y1, w1, h1, sprite1, flip_x1, flip_y1, x2, y2, w2, h2, sprite2, flip_x2, flip_y2)
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

function add_crow()
    -- Determine the x coordinate and direction based on which side the crow is coming from
    local x, direction
    if rnd() > 0.5 then
        x = 0  -- Left side
        direction = 1
    else
        x = 127  -- Right side
        direction = -1
    end

    local speed = rnd() * 2 + 1  -- Random speed between 1 and 3

    local clearance = 10

    -- Add the new crow to the table
    add(crows, {
        x = x,
        y = flr(rnd() * (128 - 2 * clearance)) + clearance,  -- Random height with clearance
        speed = speed,  -- Random speed between 1 and 3
        animation_speed = speed,  -- Animation speed is the same as the speed
        direction = direction,
        current_frame = 1
    })
end

function reset()
    diver_x = flr(rnd()*128)
    diver_y = 0
    
    target = flr(rnd()*120)
    target_direction = rnd() > 0.5 and 1 or -1
    
    current_state = game_state.playing
    
    diver_direction = direction.vertical
    diver_speed_default = 1
    diver_speed = diver_speed_default
    
    crow_timer = 0
    add_crow()
end

function _init()
	music(0)
    current_state = game_state.splash
end

function _update()
    if current_state ~= game_state.playing then
        if btn(4) then
            reset()
        end
        return
    end

    crow_timer += 1/30

    if crow_timer >= 1 then
        add_crow()
        crow_timer = 0
    end

    if btn(2) then  -- Up button
        diver_speed = 0.25 * diver_speed_default
    elseif btn(3) then  -- Down button
        diver_speed = 1.5 * diver_speed_default
    else
        diver_speed = diver_speed_default
    end

    diver_y += diver_speed

	if btn(0) then 
        diver_x -= 1 
        diver_direction = direction.left
    elseif btn(1) then 
        diver_x += 1 
        diver_direction = direction.right
    else
        diver_direction = direction.vertical
    end
    
    if diver_y >= 128 - diver_size then
        if check_box_collision(flr(diver_x) + 6, flr(diver_y) + 15, 4, 2,
                        target, 127, target_width, 1) then
            current_state = game_state.landed
        else
            current_state = game_state.fail
        end
        
        diver_y = 128 - diver_size
    end

    target += 0.9*target_direction
    if target < 0 or target > 120 then
        target_direction *= -1
    end

    for i, crow in ipairs(crows) do
        -- Update the crow's position
        crow.x += crow.speed * crow.direction

        -- Update the crow's animation frame
        crow.current_frame += crow.animation_speed
        if crow.current_frame > #crow_frames then
            crow.current_frame = 1
        end

        -- Remove the crow if it's off the screen
        if crow.x < -8 or crow.x > 136 then
            del(crows, crow)
        end

        -- get diver sprite depending on diver_direction
        local diver_sprite  
        if diver_direction == direction.vertical then
            diver_sprite = 0
        elseif diver_direction == direction.left then
            diver_sprite = 4
        elseif diver_direction == direction.right then
            diver_sprite = 2
        end

        -- Check for collision with the crow
        if check_collision(flr(diver_x), flr(diver_y), 16, 16, diver_sprite, false, false,
            flr(crow.x), flr(crow.y), 8, 8, crow_frames[flr(crow.current_frame)], crow.direction < 0, false) then
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
        print_centered("up slows and down hastens dive!", 120, 7)
        return
    else
        for _, crow in ipairs(crows) do
            local flip_x = crow.direction < 0
            spr(crow_frames[flr(crow.current_frame)], crow.x, crow.y, 1, 1, flip_x)
        end
    
        rect(target, 127, target + target_width, 127, 7)
        if current_state == game_state.fail then
            print_centered("too bad", 64, 9)
        elseif current_state == game_state.landed then
            print_centered("landed", 64, 9)
        end

    	if diver_direction == direction.vertical then
            spr(0, diver_x, diver_y, 2, 2)
        elseif diver_direction == direction.left then
            spr(4, diver_x, diver_y, 2, 2)
        elseif diver_direction == direction.right then
            spr(2, diver_x, diver_y, 2, 2)
        end

    end
end

__gfx__
00000777777000000000077777700000000007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007771dd17770000007771dd17770000007771dd177700000000000000000000000000000000000000000000000000006600000000000000000000000000000
0071dd1dd1dd17000071dd1dd1dd17000071dd1dd1dd170000000000000000000000000000000000000000000660000000660000000000000000000000000000
07dd1d1dd1d1dd7007dd1d1dd1d1dd7007dd1d1dd1d1dd7080000080800000808000008080000080866000808066008080066080000000000000000000000000
711111111111111771111111111111177111111111111117888866aa888666aa886666aa866666aa886666aa888666aa888866aa000000000000000000000000
7cccccccccccccc77cccccccccccccc77cccccccccccccc700066000006600000660000000000000000000000000000000000000000000000000000000000000
07ccccc77ccccc7007cc77cccccccc7007cccccccc77cc7000660000066000000000000000000000000000000000000000000000000000000000000000000000
007ccc7337ccc70007c7337ccccc77000077ccccc7337c7006600000000000000000000000000000000000000000000000000000000000000000000000000000
0007cc7777cc700007c7777ccc770000000077ccc7777c7000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007cc77cc70000007c77cc7700000000000077cc77c70000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000776677000000077667700000000000000007766770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000002200000000000220000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000002200000000000022000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000002200000000000002200000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000002200000000000000220000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000088880000000000008888000000000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
9f0f00002b0242b0202b0202b0202b0202b0202b0202b020270202702024020240202402024020220202202024020240202202022020240202402027020270202702027020270202702027020270201d0001d000
070f00200007515005000750007500075000050007500075000751500500075000750007500005000750007500075150050007500075000750000500075000750007515005000750007500075000050007500075
d70f00200c3250f32513325163250c3250f32513325163250c3250f32513325163250c3250f32513325163250c3250f32513325163250c3250f32513325163250c3250f32513325163250c3250f3251332516325
9f0f00202b0242b0202b0202b0202b0202b0202b0202b02027020270202402024020240202402024025220002400024000332443324032244322402e2442e2402c2442c240312443124030244302402c2442c240
010f00200007515005000750007500075000050007500075000751500500075000750007500005000750007503075150050307503075080750000508075080750107515005010750107506075000050607506075
4d0f00200c3250f32513325163250c3250f32513325163250c3250f32513325163250c3250f32513325163250f32513325163251a32514325183251b3251f3250d3251132514325183251232516325193251d325
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c00f0020006753f6053f6153f60529635296053f61532605006753f6053f6153f60529635296053f6153b625006753f6053f6153f60529635296053f61532605006753f6053f6153f60529635296053f6153b625
__music__
00 0a400102
00 0a420102
01 0a000102
02 0a030405
02 4a424445

