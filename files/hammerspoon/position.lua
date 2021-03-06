-- Permission is hereby granted, free of charge, to any person obtaining a copy of this
-- software and associated documentation files (the "Software"), to deal in the Software
-- without restriction, including without limitation the rights to use, copy, modify, merge,
-- publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
-- to whom the Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

local sizes = {2, 3, 3/2}
local fullScreenSizes = {1, 4/3, 2}

local GRID = {w = 24, h = 24}
hs.grid.setGrid(GRID.w .. 'x' .. GRID.h)
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

local pressed = {
  up = false,
  down = false,
  left = false,
  right = false
}

function nextStep(dim, offs, cb)
  if hs.window.focusedWindow() then
    local axis = dim == 'w' and 'x' or 'y'
    local oppDim = dim == 'w' and 'h' or 'w'
    local oppAxis = dim == 'w' and 'y' or 'x'
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()

    cell = hs.grid.get(win, screen)

    local nextSize = sizes[1]
    for i=1,#sizes do
      if cell[dim] == GRID[dim] / sizes[i] and
        (cell[axis] + (offs and cell[dim] or 0)) == (offs and GRID[dim] or 0)
        then
          nextSize = sizes[(i % #sizes) + 1]
        break
      end
    end

    cb(cell, nextSize)
    if cell[oppAxis] ~= 0 and cell[oppAxis] + cell[oppDim] ~= GRID[oppDim] then
      cell[oppDim] = GRID[oppDim]
      cell[oppAxis] = 0
    end

    hs.grid.set(win, cell, screen)
  end
end

function nextFullScreenStep()
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()

    cell = hs.grid.get(win, screen)

    local nextSize = fullScreenSizes[1]
    for i=1,#fullScreenSizes do
      if cell.w == GRID.w / fullScreenSizes[i] and
         cell.h == GRID.h / fullScreenSizes[i] and
         cell.x == (GRID.w - GRID.w / fullScreenSizes[i]) / 2 and
         cell.y == (GRID.h - GRID.h / fullScreenSizes[i]) / 2 then
        nextSize = fullScreenSizes[(i % #fullScreenSizes) + 1]
        break
      end
    end

    cell.w = GRID.w / nextSize
    cell.h = GRID.h / nextSize
    cell.x = (GRID.w - GRID.w / nextSize) / 2
    cell.y = (GRID.h - GRID.h / nextSize) / 2

    hs.grid.set(win, cell, screen)
  end
end

function fullDimension(dim)
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()
    cell = hs.grid.get(win, screen)

    if (dim == 'x') then
      cell = '0,0 ' .. GRID.w .. 'x' .. GRID.h
    else
      cell[dim] = GRID[dim]
      cell[dim == 'w' and 'x' or 'y'] = 0
    end

    hs.grid.set(win, cell, screen)
  end
end

-------------------------------------------
-- Key bindings
-- hyper up,down,left,right to resize windows
-------------------------------------------

hs.hotkey.bind(hyper, "down", function ()
  pressed.down = true
  if pressed.up then
    fullDimension('h')
  else
    if hs.eventtap.checkKeyboardModifiers().shift then
      fullDimension('w')
    end
    nextStep('h', true, function (cell, nextSize)
      cell.y = GRID.h - GRID.h / nextSize
      cell.h = GRID.h / nextSize
    end)
  end
end, function ()
  pressed.down = false
end)

hs.hotkey.bind(hyper, "right", function ()
  pressed.right = true
  if pressed.left then
    fullDimension('w')
  else
    if hs.eventtap.checkKeyboardModifiers().shift then
      fullDimension('h')
    end
    nextStep('w', true, function (cell, nextSize)
      cell.x = GRID.w - GRID.w / nextSize
      cell.w = GRID.w / nextSize
    end)
  end
end, function ()
  pressed.right = false
end)

hs.hotkey.bind(hyper, "left", function ()
  pressed.left = true
  if pressed.right then
    fullDimension('w')
  else
    if hs.eventtap.checkKeyboardModifiers().shift then
      fullDimension('h')
    end
    nextStep('w', false, function (cell, nextSize)
      cell.x = 0
      cell.w = GRID.w / nextSize
    end)
  end
end, function ()
  pressed.left = false
end)

hs.hotkey.bind(hyper, "up", function ()
  pressed.up = true
  if pressed.down then
      fullDimension('h')
  else
    if hs.eventtap.checkKeyboardModifiers().shift then
      fullDimension('w')
    end
    nextStep('h', false, function (cell, nextSize)
      cell.y = 0
      cell.h = GRID.h / nextSize
    end)
  end
end, function ()
  pressed.up = false
end)

-----------------------------------------------
-- hyper f to center window and clicle through different sizes
-----------------------------------------------

hs.hotkey.bind(hyper, "f", function ()
  nextFullScreenStep()
end)

-----------------------------------------------
-- hyper shift f to toggle fullscreeen
-----------------------------------------------

hs.hotkey.bind(hyperShift, 'f', function()
  hs.window.focusedWindow():toggleFullScreen()
end)

-----------------------------------------------
-- hyper c to center window
-----------------------------------------------

hs.hotkey.bind(hyper, 'c', function()
    if hs.window.focusedWindow() then
        local win = hs.window.focusedWindow()
        local f = win:frame()
        local screen = win:screen()
        local max = screen:frame()

        f.w = max.w * 0.7
        f.h = max.h * 0.7
        f.x = (max.w - f.w)/2
        f.y = (max.h - f.h)/2
        win:setFrame(f)
    else
        hs.alert.show("No active window")
    end
end)

------------------------------------------------
-- TILE WINDOWS ON CURRENT SCREEN
------------------------------------------------
hs.hotkey.bind(hyper, 't', function()
    local wins = hs.window.filter.new():setCurrentSpace(true):getWindows()
    local screen = hs.screen.mainScreen():currentMode()
    local rect = hs.geometry(0, 0, screen['w'], screen['h'])
    hs.window.tiling.tileWindows(wins, rect)
end)

-----------------------------------------------
-- hyper i for window information
-----------------------------------------------

hs.hotkey.bind(hyper, "i", function ()
  local win = hs.window.frontmostWindow()
  local id = win:id()
  local screen = win:screen()
  cell = hs.grid.get(win, screen)
  hs.alert.show(cell)
end)
