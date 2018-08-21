pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- picobricks alpha
-- by jellycat
-- 0.4.0
local ball, pad, bricks, lives, score, scene

function _init()
  scene = "start"
end

function start()
  lives = 3
  score = 0
  ball = make_ball()
  pad = make_pad()
  
  local brick_w = 9
  local brick_h = 4
  bricks = {}
  build_bricks(11, 6, brick_w, brick_h, 4)

  scene = "game"
  serve_ball()
end

function gameover()
  scene = "gameover"
  sfx(10)
end

function serve_ball()
  ball.x = 8
  ball.y = 32
  ball.vx = 1
  ball.vy = 1
end

function build_bricks(c, l, w, h, color)
  for line = 1,l do
    for col = 1,c do
      add(bricks, make_brick(4 + (col - 1) * (w + 2), 20 + (line - 1) * (h + 2), w, h, color))
    end
  end
end

function _update60()
  if scene == "game" then
    update_game()
  elseif scene == "start" then
    update_start()
  elseif scene == "gameover" then
  update_gameover()
  end
end

function update_game()
  ball:update()
  pad:update()

  for brick in all(bricks) do
    brick:update()
  end
end

function update_start()
  if (btn(5)) start()
end

function update_gameover()
  if (btn(5)) _init()
end

function _draw()
  if scene == "game" then
    draw_game()
  elseif scene == "start" then 
    draw_start()
  elseif scene == "gameover" then
    draw_gameover()
  end
end

function draw_game()
  cls(0)
  rectfill(0, 0, 127, 7, 0)
  for i=1,lives do print("♥", 4 + 8*i - 8, 2, 8) end
  print("score: "..score, 72, 2, 6)
  ball:draw()
  pad:draw()  
  for brick in all(bricks) do
    brick:draw()
  end
end

function draw_start()
  local title = "picobricks"
  local subtitle = "alpha version" 
  local cta = "press ❎ to start"
  cls(0)
  for i=1,50 do
    pset(flr(rnd(127)), flr(rnd(127)), flr(rnd(15)))
  end
  print(title, 64 - (#title / 2) * 4, 30, 8)
  print(subtitle, 64 - (#subtitle / 2) * 4, 38, 6)
  print(cta, 64 - (#cta / 2) * 4, 60, 12)
end

function draw_gameover()
  local go_text = "g a m e  o v e r"
  local cta = "press ❎ to try again"
  rectfill(-8, 30, 128, 72, 0)
  rect(-8, 30, 128, 72, 6)
  print(go_text, 64 - (#go_text / 2) * 4, 38, 8)
  print(cta, 64 - (#cta / 2) * 4, 60, 6)
end

function make_ball()
  local ball = {
    x = 5,
    y = 30,
    vx = 1,
    vy = 1,
    w = 4,
    h = 4,
    r = 2,
    --dr = 0.5,
    c = 10,

    update = function(self)
      local nextx, nexty

      nextx = self.x + self.vx
      nexty = self.y + self.vy

      if nextx <= 0  or nextx >= 127 then
        nextx = mid(0, nextx, 127)
        self.vx = -self.vx
        sfx(0)
      end
      if nexty <= 8 + self.r then 
        nexty = mid(0, nexty, 127)
        self.vy = -self.vy
        sfx(0)
      end

      if self:collide(nextx, nexty, pad) then
        -- check if ball hits pad
        -- find out which direction ball will deflect
        if self:deflect(pad) then
          ball.vx = -ball.vx
        else
          ball.vy = -ball.vy
        end
        score += 10
        sfx(1)
      end

      for brick in all(bricks) do 
        if brick.v and self:collide(nextx, nexty, brick) then
          -- check if ball hits pad
          -- find out which direction ball will deflect
          if self:deflect(brick) then
            ball.vx = -ball.vx
          else
            ball.vy = -ball.vy
          end

          brick.v = false
          sfx(3)
          score += 100
        end
      end

      ball.x = nextx
      ball.y = nexty

      if self.y > 127 then
        if lives <= 1 then
          gameover()
        else
          lives -= 1
          sfx(2)
          serve_ball()
        end
      end
    end,

    draw = function(self)
      circfill(self.x, self.y, self.r, self.c)
    end,

    collide = function(self, nextx, nexty, other)
      if (nexty - self.r > other.y + other.h) return false -- top
      if (nexty + self.r < other.y) return false -- bottom
      if (nextx - self.r > other.x + other.w) return false -- left
      if (nextx + self.r < other.x) return false -- right

      return true
    end,

    deflect = function(self, target)
      local slp = self.vy / self.vx
      local cx, cy
      if self.vx == 0 then
          return false
      elseif self.vy == 0 then
          return true
      elseif slp > 0 and self.vx > 0 then
          cx = target.x - self.x
          cy = target.y - self.y
          return cx > 0 and cy/cx < slp
      elseif slp < 0 and self.vx > 0 then
          cx = target.x - self.x
          cy = target.y + target.h - self.y
          return cx > 0 and cy/cx >= slp
      elseif slp > 0 and self.vx < 0 then
          cx = target.x + target.w - self.x
          cy = target.y + target.h - self.y
          return cx < 0 and cy/cx <= slp
      else
          cx = target.x + target.w - self.x
          cy = target.y - self.y
          return cx < 0 and cy/cx >= slp
      end
    end
  }

  return ball
end

function make_pad()
  local pad = {
    x = 52,
    y = 120,
    vx = 0,
    w = 24,
    h = 3,
    s = 3,
    c = 6,

    update = function(self)
      if btn(0) then
        self.vx = -self.s
      end
      if btn(1) then
        self.vx = self.s
      end
      self.vx *= 0.85

      self.x += self.vx
      self.x = mid(0, self.x, 127 - self.w)
    end,

    draw = function(self)
      rectfill(self.x, self.y, self.x + self.w, self.y + self.h, self.c)
    end
  }

  return pad
end

function make_brick(x, y, w, h, c)
  local brick = {
    x = x,
    y = y,
    w = w,
    h = h,
    c = c,
    v = true,

    update = function(self)
    end,

    draw = function(self)
      if (self.v) rectfill(self.x, self.y, self.x + self.w, self.y + self.h, self.c)
    end
  }

  return brick
end
__sfx__
010100001836018360183501833018320183100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010100002436024360243502433024320243100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01080000155651356511555105550e5450c5450b53509531095210951109511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100003036030360303503033030320303100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00000c5520c5420c5300c5000c5500c5400c5000c5500c5000c5520c5520c5400c53110541105500c5000e5500c5000e5520e5400e5310c5510c5000c5500c550005000b5500b5510c5510c5520c5420c532
011000000c043000000000000000246150c04300000000000c0430000000000000002461500000000000c0430c043000000000000000246150c04300000000000c04300000000000c043246150c043000000c043
__music__
00 0a4b4344

