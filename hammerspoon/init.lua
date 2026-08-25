-- Enables the bundled `hs` CLI (/opt/homebrew/bin/hs) to evaluate Lua in this
-- config, which is how the Ghostty image paste below can be inspected/tested.
require('hs.ipc')

local function keyCode(key, modifiers)
   modifiers = modifiers or {}
   return function()
      hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), true):post()
      hs.timer.usleep(1000)
      hs.eventtap.event.newKeyEvent(modifiers, string.lower(key), false):post()      
   end
end

local function remapKey(modifiers, key, keyCode)
   hs.hotkey.bind(modifiers, key, keyCode, nil, keyCode)
end

local function disableAllHotkeys()
   for k, v in pairs(hs.hotkey.getHotkeys()) do
      v['_hk']:disable()
   end
end

local function enableAllHotkeys()
   for k, v in pairs(hs.hotkey.getHotkeys()) do
      v['_hk']:enable()
   end
end

-- Paste a clipboard image into Ghostty as a file path.
--
-- Ghostty's Cmd+V handler only accepts file URLs and strings, so a macOS
-- screenshot (raw PNG/TIFF data with no file URL) pastes nothing at all.
-- Claude Code has its own Ctrl+V clipboard reader that covers this, but
-- ctrl+v is remapped to pagedown further down this file, so intercept Cmd+V
-- instead: write the image to a temp file and type its path, which Claude
-- Code accepts as an image reference.
local ghosttyBundleID = "com.mitchellh.ghostty"
-- TMPDIR is a per-user directory that macOS purges on its own; /tmp is
-- world-writable and shared, so do not write image data there.
local imagePasteDir = (os.getenv("TMPDIR") or "/tmp/") .. "ghostty-image-paste"
local imagePasteCount = 0

local function nextImagePath(extension)
   imagePasteCount = imagePasteCount + 1
   return string.format("%s/%s-%d.%s", imagePasteDir,
                        os.date("%Y%m%d-%H%M%S"), imagePasteCount, extension)
end

local function writeFile(path, data)
   local file = io.open(path, "wb")
   if not file then
      return false
   end
   file:write(data)
   file:close()
   return true
end

-- Returns the path of a file holding the clipboard image, or nil when the
-- clipboard holds no image or holds something Ghostty already pastes correctly.
local function clipboardImageToFile()
   local available = {}
   for _, uti in ipairs(hs.pasteboard.contentTypes() or {}) do
      available[uti] = true
   end
   if available["public.file-url"] or available["public.utf8-plain-text"] then
      return nil
   end

   hs.fs.mkdir(imagePasteDir)

   -- Write the clipboard bytes verbatim for formats Claude Code accepts.
   -- Going through hs.image would re-encode, and its point-sized geometry
   -- halves the resolution of a Retina screenshot.
   for _, format in ipairs({ { uti = "public.png", extension = "png" },
                             { uti = "public.jpeg", extension = "jpg" } }) do
      if available[format.uti] then
         local data = hs.pasteboard.readDataForUTI(nil, format.uti)
         if data and #data > 0 then
            local path = nextImagePath(format.extension)
            if writeFile(path, data) then
               return path
            end
         end
      end
   end

   -- Anything else (TIFF, PDF, ...) is not accepted by Claude Code, so convert.
   local image = hs.pasteboard.readImage()
   if not image then
      return nil
   end
   local path = nextImagePath("png")
   -- scale = true saves the pixel dimensions rather than the point dimensions.
   if image:saveToFile(path, true, "PNG") then
      return path
   end
   return nil
end

-- Global like appsWatcher below: an eventtap that is only referenced from a
-- local is eligible for collection and stops firing.
ghosttyImagePasteTap = hs.eventtap.new(
   { hs.eventtap.event.types.keyDown },
   function(event)
      if event:getKeyCode() ~= hs.keycodes.map.v then
         return false
      end
      if not event:getFlags():containExactly({ 'cmd' }) then
         return false
      end
      -- The tap is started and stopped by the app watcher below, but a missed
      -- activation event must never let this steal Cmd+V from another app.
      local app = hs.application.frontmostApplication()
      if not app or app:bundleID() ~= ghosttyBundleID then
         return false
      end

      local path = clipboardImageToFile()
      if not path then
         return false
      end
      hs.eventtap.keyStrokes(path .. ' ')
      hs.alert.show('image -> ' .. path, 1)
      return true
   end)

local function updateGhosttyImagePasteTap(app)
   if app and app:bundleID() == ghosttyBundleID then
      ghosttyImagePasteTap:start()
   else
      ghosttyImagePasteTap:stop()
   end
end

local function handleGlobalAppEvent(name, event, app)
   if event == hs.application.watcher.activated then
      -- hs.alert.show(name)
      if name == "iTerm2" or name == "Terminal" then
         disableAllHotkeys()
      else
         enableAllHotkeys()
      end
      updateGhosttyImagePasteTap(app)
   end
end

updateGhosttyImagePasteTap(hs.application.frontmostApplication())

appsWatcher = hs.application.watcher.new(handleGlobalAppEvent)
appsWatcher:start()

-- カーソル移動
remapKey({'ctrl'}, 'f', keyCode('right'))
-- remapKey({'ctrl'}, 'b', keyCode('left'))
remapKey({'ctrl'}, 'n', keyCode('down'))
remapKey({'ctrl'}, 'p', keyCode('up'))

-- テキスト編集
remapKey({'ctrl'}, 'w', keyCode('x', {'cmd'}))
remapKey({'ctrl'}, 'y', keyCode('v', {'cmd'}))

-- ページスクロール
remapKey({'ctrl'}, 'v', keyCode('pagedown'))
remapKey({'alt'}, 'v', keyCode('pageup'))
remapKey({'cmd', 'shift'}, ',', keyCode('home'))
remapKey({'cmd', 'shift'}, '.', keyCode('end'))

