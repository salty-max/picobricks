pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- todo
-- 6.   powerups
--        speed down
--        mega ball
--        (multiball) ?
-- 7.   more juicyness
--        arrow animation
--        combo text
--        power up text
--        text blinking
--        particles
--        screen shakes
-- 8.   high score
-- 9.   timer
-- 10.  better collisions
-- 11.  gameplay tweaks
--        smaller paddle ?  

-- brick types
-- b : regular
-- h : hardened
-- i : indestructible
-- s : explosive
-- p : powerup

local ball, pad, bricks, powups, lives, score, mult, chain, levels, level, scene, debug, powerup, powerup_t

function _init()
  scene = "start"
  debug = ""

  levels = {
    "b3xb3xb3/xbxxh1b1h1xxbx/xpxxh1s1h1xxpx/b1h1b1xb3xb1h1b1",
    "x5b1x5/s9s2",
    "b9b2/x1p9",
    "b9b2/b9b2/b9b2",
    "x5s1x5/x4b3x4/x1i9",
  }
  level = 3
  lives = 3
  score = 0
  mult = 1
end

function start()
  local brick_w = 10
  local brick_h = 5
  local brick_offset = 1
  
  scene = "game"
  bricks = {}
  powups = {}
  chain = 1
  score = 0

  ball = make_ball()
  pad = make_pad()
  build_bricks(levels[level], brick_w, brick_h, brick_offset)

  serve_ball()
end

function nextlevel()
  level += 1
  start()
end

function gameover()
  scene = "gameover"
  sfx(20)
end

function serve_ball()
  ball.x = 64
  ball.y = pad.y - ball.r
  ball.vx = 1
  ball.vy = -1
  ball.a = 1
  ball.sticky = true
  ball.sticky_x = flr(pad.w / 2)

  chain = 1
  powerup = ""
  powerup_s = 0
  powerup_t = 0
end

function build_bricks(lvl, w, h, o)
  local i, j, k, id, chr, last
  j = 0
  id = 0

  for i = 1,#lvl do
    j += 1
    id += 1
    chr = sub(lvl, i, i)
    if chr == "b" or chr == "h" or chr =="i" or chr == "s" or chr == "p" then
      last = chr
      set_brick(id, chr, j, w, h, o)
    elseif chr == "x" then
      last = "x"
    elseif chr == '/' then
      j = flr((j - 1) / 11) * 11
    elseif chr >= "0" and chr <= "9" then
      for k = 1,tonum(chr) - 1 do
        set_brick(id, last, j, w, h, o)
        j += 1
        id += 1
      end
      j -= 1
      id -= 1
    end
    
  end
end

function set_brick(id, t, n, w, h, o)
  if t == "x" then
    -- do nothing
  else
    add(bricks, make_brick(id, 4 + ((n - 1) % 11) * (w + o), 20 + flr((n - 1) / 11) * (h + o), w, h, t))
  end
end

function _update60()
  if scene == "game" then
    update_game()
  elseif scene == "start" then
    update_start()
  elseif scene == "gameover" then
    update_gameover()
  elseif scene == "levelend" then
    update_levelend()
  end
end

function update_game()
  local dest_bricks = {}

  ball:update()
  pad:update()

  for brick in all(bricks) do
    brick:update()
    brick:set_type()

    if (brick.t != "i") add(dest_bricks, brick)
  end

  for pow in all(powups) do
    pow:update()
  end

  if (#dest_bricks < 1) then 
    
    if level == #levels then
      -- todo
      -- nice end game screen
      scene = "start"
    else
      scene = "levelend"
    end
  end

  if (powerup != "") powerup_t -= 1
  if (powerup_t <= 0) powerup = ""

  if powerup == "rdc" then
    mult = 2
  else
    mult = 1
  end
end

function update_start()
  if (btnp(5)) start()
end

function update_gameover()
  if (btnp(5)) scene = "start"
end

function update_levelend()
  if (btnp(5)) nextlevel()
end

function _draw()
  if scene == "game" then
    draw_game()
  elseif scene == "start" then 
    draw_start()
  elseif scene == "gameover" then
    draw_gameover()
  elseif scene == "levelend" then
    draw_levelend()
  end
end

function draw_game()
  cls(1)
  if (debug != "") print(debug, 120, 120, 6)
  draw_ui()
  ball:draw()
  pad:draw()  
  for brick in all(bricks) do
    brick:draw()
  end

  for pow in all(powups) do
    pow:draw()
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

function draw_levelend()
  local lo_text = "stage clear !"
  local cta = "press ❎ to continue"
  local score_text = "your score: "..score
  rectfill(-8, 30, 128, 72, 0)
  rect(-8, 30, 128, 72, 6)
  print(lo_text, 64 - (#lo_text / 2) * 4, 38, 11)
  print(score_text, 64 - (#score_text / 2) * 4, 46, 7)
  print(cta, 64 - (#cta / 2) * 4, 60, 6)
end

function draw_ui()
  rectfill(0, 0, 127, 8, 0)
  for i=1,lives do print("♥", 4 + 8*i - 8, 2, 8) end
  handle_score()
  if powerup != "" then
  spr(powerup_s, 4, 120)
  print(powerup_t, 12, 120, 7)
  end
end

function handle_score()
  local chain_color

  if chain > 2 and chain < 5 then
    chain_color = 10
  elseif chain >= 5 and chain <= 7 then
    chain_color = 9
  elseif chain == 8 then
    chain_color = 8
  else
    chain_color = 7
  end

  -- multiplier
  print("x"..chain, 60, 2, chain_color)
  -- score
  print("score: "..score, 72, 2, 6)
end

function hit_brick(b, combo)
  if b.t == "b" then
    sfx(3 + (chain - 1))
    if combo then
      score += (b.pts * chain) * mult
      chain += 1
      chain = mid(1, chain, 8)
    end
    del(bricks, b)
  elseif b.t == 's' then
    b.t = "rex"
    sfx(3 + (chain - 1))
    if combo then
      score += (b.pts * chain) * mult
      chain += 1
      chain = mid(1, chain, 8)
    end
  elseif b.t == "h" then
    b.t = "b"
    sfx(3 + (chain - 1))
  elseif b.t == "i" then
    sfx(11)
  elseif b.t == "p" then
    sfx(3 + (chain - 1))
    if combo then
      score += (b.pts * chain) * mult
      chain += 1
      chain = mid(1, chain, 8)
    end
    b:spawn_pill("spd")
    del(bricks, b)
  end
end

function check_explosions()
  for brick in all(bricks) do
    if brick.t == "rex" then
      brick.t = "ex"
    elseif brick.t == "ex" then
      explode_bricks(brick)
    elseif brick.t == "rex" then
      brick.t = "ex"
    end 
  end
end

function explode_bricks(b)
  for brick in all(bricks) do
    if brick.id != b.id and abs(brick.x - b.x) <= brick.w + 1 and abs(brick.y - b.y) <= brick.h + 1 then
      hit_brick(brick, false)
    end
  end
  del(bricks, b)
end

function collide(a, b)
  if (a.x > b.x + b.w) return false 
  if (a.x + a.w < b.x) return false 
  if (a.y > b.y + b.h) return false 
  if (a.y + a.h < b.y) return false 

  return true
end

function activate_powup(type)
end

function make_ball()
  local ball = {
    x = 64,
    y = 72,
    vx = 1,
    vy = 1,
    a = 1,
    w = 4,
    h = 4,
    r = 2,
    s = 16,
    --dr = 0.5,
    c = 10,
    sticky = true,
    sticky_x = 0,

    update = function(self)
      local nextx, nexty

      if self.sticky and btnp(5) then
        self.sticky = false
      end

      if self.sticky then
        self.x = pad.x + self.sticky_x
        self.y = pad.y - self.r - 1
      else
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

        if self:bounce(nextx, nexty, pad) then
          -- check if ball hits pad
          -- find out which direction ball will deflect
          if self:deflect(pad) then
            -- ball hits paddle sideways
            self.vx = -self.vx
            if self.x < pad.x + pad.w / 2 then
              nextx = pad.x - self.r
            else
              nextx = pad.x + pad.w + self.r
            end
          else
            -- ball hits paddle on top / bottom
            self.vy = -self.vy
            if self.y > pad.y then
              -- bottom
              nexty = pad.y + pad.h + self.r
            else
              -- top
              nexty = pad.y - self.r

              if abs(pad.vx) > 2 then
                -- change angle
                if sgn(self.vx) == sgn(pad.vx) then
                  -- flatten angle
                  self:set_angle(mid(0, self.a - 1, 2))
                else
                  -- raise angle
                  if (self.a == 2) self.vx = -self.vx
                  self:set_angle(mid(0, self.a + 1, 2))  
                end
              end
            end
          end
          chain = 1
          sfx(1)
          if (powerup == "sty") and self.vy < 0 then
            self.sticky = true
            self.sticky_x = self.x - pad.x
          end
        end

        local brick_hit = false
        for brick in all(bricks) do 
          if self:bounce(nextx, nexty, brick) then
            -- check if ball hits brick
            -- find out which direction ball will deflect
            if not brick_hit then
              if self:deflect(brick) then
                -- ball hits brick sideways
                self.vx = -self.vx
                if self.x < brick.x + brick.w / 2 then
                  nextx = brick.x - self.r
                else
                  nextx = brick.x + brick.w + self.r
                end
              else
                -- ball hits brick on top / bottom
                self.vy = -self.vy
                if self.y > brick.y then
                  -- bottom
                  nexty = brick.y + brick.h + self.r
                else
                  -- top
                  nexty = brick.y - self.r
                end
              end
            end

            brick_hit = true
            hit_brick(brick, true)
          end

          self.x = nextx
          self.y = nexty
        end
      end

      if self.y > 127 then
        if lives <= 1 then
          gameover()
        else
          lives -= 1
          sfx(2)
          serve_ball()
        end
      end

      check_explosions()
    end,

    draw = function(self)
      --circfill(self.x, self.y, self.r, 7)
      spr(self.s, self.x - self.r, self.y - self.r)

      -- serve preview
      if (self.sticky) line(self.x + self.vx * 4, self.y + self.vy * 4, self.x + self.vx * 8, self.y + self.vy * 8, 10)
    end,

    bounce = function(self, nextx, nexty, other)
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
    end,

    set_angle = function(self, a)
      self.a = a

      if a == 2 then
        self.vx = 0.50 * sgn(self.vx)
        self.vy = 1.30 * sgn(self.vy)
      elseif a == 0 then
        self.vx = 1.30 * sgn(self.vx)
        self.vy = 0.50 * sgn(self.vy)
      else
        self.vx = 1 * sgn(self.vx)
        self.vx = 1 * sgn(self.vx)
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
        if (ball.sticky) ball.vx = -1
      end
      if btn(1) then
        self.vx = self.s
        if (ball.sticky) ball.vx = 1
      end
      self.vx *= 0.85

      self.x += self.vx
      self.x = mid(0, self.x, 127 - self.w)

      if (powerup == "exp") then
        self.w = 32
      elseif (powerup == "rdc") then 
        self.w = 16
      else
        self.w = 24
      end
    end,

    draw = function(self)
      if (powerup == "exp") then
        spr(37, self.x, self.y - 2, 4, 1)
      elseif (powerup == "rdc") then 
        spr(35, self.x, self.y - 2, 2, 1)
      else
        spr(32, self.x, self.y - 2, 3, 1)
      end
    end
  }

  return pad
end

function make_brick(id, x, y, w, h, t)
  local brick = {
    id = id,
    x = x,
    y = y,
    w = w,
    h = h,
    t = t,
    --hp = 0,
    c = 0,
    sx = 0,
    sy = 0,
    pts = 0,
    --v = true,

    update = function(self)
    end,

    draw = function(self)
      palt(0, false)
      sspr(self.sx, self.sy, self.w, self.h, self.x, self.y)
      palt()
    end,

    set_type = function(self)
      if self.t == "b" then
        self.sx = 8
        self.c = 14
        --self.hp = 1
        self.pts = 50
      elseif self.t == "h" then
        self.sx = 18
        self.c = 12
        --self.hp = 2
        self.pts = 100
      elseif self.t == "i" then
        self.sx = 48
        self.c = 13
        --self.hp = 1
        self.pts = 0
      elseif self.t == "s" then
        self.sx = 28
        self.c = 9
        --self.hp = 1
        self.pts = 300
      elseif self.t == "p" then
        self.sx = 38
        self.c = 11
        --self.hp = 1
        self.pts = 200
      end
    end,

    spawn_pill = function(self)
      local types = {"spd", "1up", "sty", "exp", "rdc", "meg", "mlt"}
      add(powups, make_powup("rdc", self.x + self.w / 2, self.y + self.h + 2))
    end
  }

  return brick
end

function make_powup(t, x, y)
  local pow = {
    x = x,
    y = y,
    vy = 0.5,
    w = 4,
    h = 4,
    s = 0,
    t = t,

    update = function(self)
      self.y += self.vy

      if (self.y >= 128) del(powups, self)

      if collide(self, pad) then
        self:activate()
        sfx(12)
        del(powups, self)
      end
    end,

    draw = function(self)
      if self.t == "spd" then
        self.s = 48
      elseif self.t == "1up" then
        self.s = 49
      elseif self.t == "sty" then
        self.s = 50
      elseif self.t == "exp" then
        self.s = 51
      elseif self.t == "rdc" then
        self.s = 52
      elseif self.t == "meg" then
        self.s = 53
      elseif self.t == "mlt" then
        self.s = 54
      end

      spr(self.s, self.x, self.y)
    end,

    activate = function(self)
      if self.t == "spd" then
        -- slow down ball
        self:reset(self.t, 600)
      elseif self.t == "1up" then
        lives += 1
        self:reset("", 0)
      elseif self.t == "sty" then
        self:reset(self.t, 600)
      elseif self.t == "exp" then
        self:reset(self.t, 600)
        -- expand paddle
      elseif self.t == "rdc" then
        self:reset(self.t, 600)
        -- reduce paddle
      elseif self.t == "meg" then
        self:reset(self.t, 600)
        -- megaball
      elseif self.t == "mlt" then
        self:reset(self.t, 600)
        -- multiball
      end
    end,

    reset = function(self, type, timer)
      powerup = type
      powerup_t = 600
      powerup_s = self.s
    end
  }

  return pow
end

__gfx__
00000000277777777717777777775aa55aa55a377777777757777777770000000000000000000000000000000000000000000000000000000000000000000000
000000002eeeeeeee71cccccccc799009900993bbbbbbbb756dd66dd670000000000000000000000000000000000000000000000000000000000000000000000
007007002eeeeeeee71cccccccc790099009903bbbbbbbb75dd66dd6670000000000000000000000000000000000000000000000000000000000000000000000
000770002eeeeeeee71cccccccc700990099003bbbbbbbb75d66dd66d70000000000000000000000000000000000000000000000000000000000000000000000
00077000222222222711111111170440044004333333333755555555570000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaa70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06700000000000000000077006700000000007700670000000000000000000000000077000000000000000000000000000000000000000000000000000000000
56677777777777777777766756677777777776675667777777777777777777777777766700000000000000000000000000000000000000000000000000000000
56666666666666666666666756666666666666675666666666666666666666666666666700000000000000000000000000000000000000000000000000000000
56655555555555555555566756655555555556675665555555555555555555555555566700000000000000000000000000000000000000000000000000000000
05500000000000000000056005500000000005600550000000000000000000000000056000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06670000066700000667000006670000066700000667000006670000000000000000000000000000000000000000000000000000000000000000000000000000
69997000688870006bbb7000622270006ddd70006ccc70006aaa7000000000000000000000000000000000000000000000000000000000000000000000000000
69996000688860006bbb6000622260006ddd60006ccc60006aaa6000000000000000000000000000000000000000000000000000000000000000000000000000
59996000588860005bbb6000522260005ddd60005ccc60005aaa6000000000000000000000000000000000000000000000000000000000000000000000000000
05660000056600000566000005660000056600000566000005660000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0002020202020002020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100001836018360183501833018320183100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010100002436024360243502433024320243100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01080000155651356511555105550e5450c5450b53509531095210951109511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002a34030340303303032030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200002c34032340323303232030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200002e34034340343303432030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200003034036340363303632030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200003234038340383303832030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
00020000343403a3403a3303a32030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
00020000363403c3403c3303c32030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01020000383403e3403e3303e32030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010200003b5530c5020c5000c5000c5000c5000c5000c5000c5000c5020c5020c5000c50110501105000c5000e5000c5000e5020e5000e5010c5010c5000c5000c500005000b5000b5010c5010c5020c5020c502
010800001b0501b051270502705033051330523305233052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00000c5520c5420c5300c5000c5500c5400c5000c5500c5000c5520c5520c5400c53110541105500c5000e5500c5000e5520e5400e5310c5510c5000c5500c550005000b5500b5510c5510c5520c5420c532
__music__
00 0a4b4344

