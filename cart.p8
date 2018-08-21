pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
local ball, pad, lives, score, scene

function _init()
  scene = "start"
end

function start()
  lives = 3
  score = 0
  ball = make_ball()
  pad = make_pad()
  scene = "game"
  serve_ball()
end

function gameover()
  scene = "gameover"
  sfx(10)
end

function serve_ball()
  ball.x = 5
  ball.y = 30
  ball.vx = 1
  ball.vy = 1
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
  cls(1)
  rectfill(0, 0, 127, 7, 0)
  for i=1,lives do print("♥", 4 + 8*i - 8, 2, 8) end
  print("score: "..score, 72, 2, 6)
  ball:draw()
  pad:draw()  
end

function draw_start()
  local title = "picobricks"
  local subtitle = "alpha version 0.3.0" 
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

        sfx(1)
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
      -- calculate whether to deflect the ball
      -- horizontally and or vertical when it hits a box
      if self.vx == 0 then
        -- moving vertically
        return false
      elseif self.vy == 0 then
        -- moving horizontally
        return true
      else
        -- moving diagonally
        -- calculate slope
        local slp = self.vx / self.vy
        local cx, cy
        --check variants
        if slp > 0 and self.vx > 0 then
          -- moving down right
          debug = "dr"
          cx = target.x - self.x
          cy = target.y - self.y
          if cx <= 0 then
            return false
          elseif cy / cx < slp then
            return true
          else
            return false
          end
        elseif slp < 0 and self.vx > 0 then
          -- moving up right
          debug = "ur"
          cx = target.x - self.x
          cy = target.y + target.h - self.y
          if cx <= 0 then
            return false
          elseif cy / cx < slp then
            return false
          else
            return true
          end
        elseif slp > 0 and self.vx < 0 then
          -- moving up left
          debug = "ul"
          cx = target.x + target.w - self.x
          cy = target.y + target.h - self.y
          if cx >= 0 then
            return false
          elseif cy / cx > slp then
            return false
          else
            return true
          end
        else
          -- moving down left
          debug = "dl"
          cx = target.x + target.w - self.x
          cy = target.y - self.y
          if cx >= 0 then
            return false
          elseif cy / cx < slp then
            return false
          else
            return true
          end
        end
      end
      return false
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
      if btn(0) and self.x > 0 then
        self.vx = -self.s
      end
      if btn(1) and self.x + self.w < 127 then
        self.vx = self.s
      end
      self.vx *= 0.8

      self.x += self.vx
    end,

    draw = function(self)
      rectfill(self.x, self.y, self.x + self.w, self.y + self.h, self.c)
    end
  }

  return pad
end

__sfx__
010100001836018360183501833018320183100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010100002436024360243502433024320243100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01080000155651356511555105550e5450c5450b53509531095210951109511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

