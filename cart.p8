pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
local ball
local pad

function _init()
  ball = {
    x = 62,
    y = 62,
    vx = 4,
    vy = 2,
    r = 2,
    dr = 0.5,
    c = 7
  }

  pad = {
    x = 52,
    y = 120,
    vx = 0,
    w = 24,
    h = 3,
    s = 5,
    c = 8
  }
end

function _update()
  ball.x += ball.vx
  ball.y += ball.vy

  if btn(0) then
    pad.vx = -pad.s
  end
  if btn(1) then
    pad.vx = pad.s
  end
  pad.vx *= 0.75
  pad.x += pad.vx

  if ball.x <= 0 or ball.x >= 127 then
    ball.vx = -ball.vx
    sfx(0)
  end
  if ball.y <= 0 or ball.y >= 127 then 
    ball.vy = -ball.vy
    sfx(0)
  end
end

function _draw()
  cls(1)
  print("fps: "..stat(7), 4, 4, 7)
  rectfill(pad.x, pad.y, pad.x + pad.w, pad.y + pad.h, pad.c)
  circfill(ball.x, ball.y, ball.r, ball.c)
end

__sfx__
000100001834018340183301832018310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
