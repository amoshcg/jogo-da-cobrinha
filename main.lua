require "palette"
require "sprites"

-- ===================================================================
-- Jogo da Cobrinha
-- Setas movem a cobra. Z comeca / reinicia a partida.
-- ===================================================================

local CELL = 10               -- tamanho de cada casa em pixels
local COLS, ROWS = 48, 25     -- campo de 480x250
local TOP = 20                -- faixa do placar no topo
local SPEED_START = 8         -- quadros entre cada passo
local SPEED_MIN = 3

-- Cores (paleta DB32)
local cache = {}
local function C(hex)
    local c = cache[hex]
    if not c then
        c = Palette.hex(hex)
        cache[hex] = c
    end
    return c
end

local state = "start"         -- "start", "play" ou "over"
local snake, dir, next_dir, food
local score, best = 0, 0
local speed, timer = SPEED_START, 0

local function occupied(x, y)
    for i = 1, #snake do
        if snake[i].x == x and snake[i].y == y then
            return true
        end
    end
    return false
end

local function place_food()
    if #snake >= COLS * ROWS then
        food = nil
        return
    end
    local x, y
    repeat
        x = math.random(0, COLS - 1)
        y = math.random(0, ROWS - 1)
    until not occupied(x, y)
    food = { x = x, y = y }
end

local function new_game(frame)
    math.randomseed(frame)
    local cx, cy = COLS // 2, ROWS // 2
    snake = {
        { x = cx, y = cy },
        { x = cx - 1, y = cy },
        { x = cx - 2, y = cy },
    }
    dir = { x = 1, y = 0 }
    next_dir = dir
    score = 0
    speed = SPEED_START
    timer = 0
    place_food()
    state = "play"
end

local function read_input()
    local d
    if ui.btn(LEFT) then
        d = { x = -1, y = 0 }
    elseif ui.btn(RIGHT) then
        d = { x = 1, y = 0 }
    elseif ui.btn(UP) then
        d = { x = 0, y = -1 }
    elseif ui.btn(DOWN) then
        d = { x = 0, y = 1 }
    end
    -- nao deixa a cobra virar 180 graus
    if d and not (d.x == -dir.x and d.y == -dir.y) then
        next_dir = d
    end
end

local function step()
    dir = next_dir
    local head = snake[1]
    local nx, ny = head.x + dir.x, head.y + dir.y

    if nx < 0 or nx >= COLS or ny < 0 or ny >= ROWS then
        state = "over"
        return
    end

    local eating = food and nx == food.x and ny == food.y
    if not eating then
        table.remove(snake)   -- a cauda sai antes de checar a colisao
    end

    if occupied(nx, ny) then
        state = "over"
        return
    end

    table.insert(snake, 1, { x = nx, y = ny })

    if eating then
        score = score + 1
        if score > best then
            best = score
        end
        if score % 5 == 0 and speed > SPEED_MIN then
            speed = speed - 1
        end
        place_food()
    end
end

local function cell(x, y, color)
    local px, py = x * CELL, TOP + y * CELL
    ui.rectfill(px + 1, py + 1, px + CELL - 2, py + CELL - 2, color)
end

local function print_center(text, y, color)
    local x = (480 - ui.text_width(text)) // 2
    ui.print(text, x, y, color)
end

local function draw(frame)
    ui.cls(C(0x222034))

    -- placar
    ui.rectfill(0, 0, 479, TOP - 1, C(0x3f3f74))
    ui.print("PONTOS: " .. score, 8, 6, C(0xffffff))
    local rec = "RECORDE: " .. best
    ui.print(rec, 472 - ui.text_width(rec), 6, C(0xfbf236))

    if snake then
        if food then
            cell(food.x, food.y, C(0xd95763))
        end
        for i = #snake, 2, -1 do
            cell(snake[i].x, snake[i].y, C(0x6abe30))
        end
        cell(snake[1].x, snake[1].y, C(0x99e550))
    end

    if state == "start" then
        print_center("JOGO DA COBRINHA", 110, C(0x99e550))
        if frame % 60 < 40 then
            print_center("APERTE Z PARA COMECAR", 140, C(0xffffff))
        end
        print_center("SETAS MOVEM A COBRA", 160, C(0x9badb7))
    elseif state == "over" then
        ui.rectfill(140, 100, 339, 170, C(0x000000))
        ui.rect(140, 100, 339, 170, C(0xac3232))
        print_center("FIM DE JOGO", 112, C(0xd95763))
        print_center("PONTOS: " .. score, 130, C(0xffffff))
        if frame % 60 < 40 then
            print_center("APERTE Z PARA REINICIAR", 150, C(0xffffff))
        end
    end
end

function loop(frame)
    for i = 1, #Palette do
        ui.palset(i - 1, Palette[i])
    end
    ui.clip(0, 0, 480, 270)
    ui.camera(0, 0)

    if state == "play" then
        read_input()
        timer = timer + 1
        if timer >= speed then
            timer = 0
            step()
        end
    elseif ui.btnp(BTN_Z) then
        new_game(frame)
    end

    draw(frame)
end
