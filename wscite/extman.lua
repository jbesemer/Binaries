local _MarginClick,_DoubleClick,_SavePointLeft = {},{},{}
local _SavePointReached,_Open,_SwitchFile = {},{},{}
local _BeforeSave,_Save,_Char = {},{},{}
local _Word,_LineEd,_LineOut = {},{},{}
local _UserListSelection
local _remove = {}
local append = table.insert

function OnUserListSelection(tp,str)
  if _UserListSelection then 
     local callback = _UserListSelection 
     _UserListSelection = nil
     return callback(str)
  else return false end
end

local function DispatchOne(handlers,arg)
  for i,handler in handlers do
    local fn = handler
    if _remove[fn] then
        handlers[i] = nil
       _remove[fn] = nil
    end
    local ret = fn(arg)
    if ret then return ret end
  end
  return false
end

function OnMarginClick()
  return DispatchOne(_MarginClick)
end

function OnDoubleClick()
  return DispatchOne(_DoubleClick)
end

function OnSavePointLeft()
  return DispatchOne(_SavePointLeft)
end

function OnSavePointReached()
  return DispatchOne(_SavePointReached)
end

function OnChar(ch)
  return DispatchOne(_Char,ch)
end

function OnSave(file)
  return DispatchOne(_Save,file)
end

function OnBeforeSave(file)
  return DispatchOne(_BeforeSave,file)
end

function OnSwitchFile(file)
  return DispatchOne(_SwitchFile,file)
end

function OnOpen(file)
  return DispatchOne(_Open,file)
end

-- may optionally ask that this handler be immediately
-- removed after it's called
local function append_unique(tbl,fn,remove)
  local once_only
  if type(fn) == 'string' then
     once_only = fn == 'once'
     fn = remove
     remove = nil
     if once_only then _remove[fn] = fn end
  else
    _remove[fn] = nil
  end
  local idx 
  for i,handler in pairs(tbl) do
     if handler == fn then idx = i; break end
  end
  if idx then
    if remove then
      table.remove(tbl,idx)
    end
  else
    if not remove then
      append(tbl,fn)
    end
  end        
end

function scite_OnMarginClick(fn,remove)
  append_unique(_MarginClick,fn,remove)
end

function scite_OnDoubleClick(fn,remove)
  append_unique(_DoubleClick,fn,remove)
end

function scite_OnSavePointLeft(fn,remove)
  append_unique(_SavePointLeft,fn,remove)
end

function scite_OnSavePointReached(fn,remove)
  append_unique(_SavePointReached,fn,remove)
end

function scite_OnOpen(fn,remove)
  append_unique(_Open,fn,remove)
end

function scite_OnSwitchFile(fn,remove)
  append_unique(_SwitchFile,fn,remove)
end

function scite_OnBeforeSave(fn,remove)
  append_unique(_BeforeSave,fn,remove)
end

function scite_OnSave(fn,remove)
  append_unique(_Save,fn,remove)
end

function scite_OnChar(fn,remove)
  append_unique(_Char,fn,remove)  
end

 local find = string.find
 local word_start,in_word,current_word

 local function on_word_char(s)
     if not in_word then
        if find(s,'%w') then 
      -- we have hit a word!
         word_start = editor.CurrentPos
         in_word = true
         current_word = s
      end
    else -- we're in a word
   -- and it's another word character, so collect
     if find(s,'%w') then   
       current_word = current_word..s
     else
       -- leaving a word; call the handler
       local word_end = editor.CurrentPos
       DispatchOne(_Word, {word=current_word,
               startp=word_start,endp=editor.CurrentPos,
               ch = s
            })     
       in_word = false
     end   
    end 
  -- don't interfere with usual processing!
    return false
  end  


function scite_OnWord(fn,remove)
  append_unique(_Word,fn,remove)   
  if not remove then
     scite_OnChar(on_word_char)
  else
     scite_OnChar(on_word_char,'remove')
  end
end

local last_pos = 0

local function grab_line_from(pane)
        local line_pos = pane.CurrentPos
        local lineno = pane:LineFromPosition(line_pos)-1
        -- strip linefeeds (Windows is a special case as usual!)
        local endl = 2
        if scite_GetProp('PLAT_WIN') then endl = 3 end
        local line = string.sub(pane:GetLine(lineno),1,-endl)
        return line
end

local function on_line_char(ch,result)
  if ch == '\n' or ch == '\r' then
     if ch == '\n' then
       local line_pos = editor.CurrentPos
       if line_pos > last_pos then
 	    DispatchOne(_LineEd,grab_line_from(editor))
            last_pos = 0             
       else
	    DispatchOne(_LineOut,grab_line_from(output))
      end
    end
    return result
  else
     last_pos = editor.CurrentPos
  end
  return false
end

local function on_line_editor_char(ch)
  return on_line_char(ch,false)
end

local function on_line_output_char(ch)
  return on_line_char(ch,true)
end

local function set_line_handler(fn,remove,handler,on_char)
  append_unique(handler,fn,remove)   
  if not remove then
     scite_OnChar(on_char)
  else
     scite_OnChar(on_char,'remove')
  end
end

function scite_OnEditorLine(fn,remove)
  set_line_handler(fn,remove,_LineEd,on_line_editor_char)  
end
 
function scite_OnOutputLine(fn,remove)
  set_line_handler(fn,remove,_LineOut,on_line_output_char)
end

local next_user_id = 13 -- arbitrary

-- the handler is always reset!
function scite_UserListShow(list,start,fn)
  local s = ''
  local sep = ';'
  local n = table.getn(list)
  for i = start,n-1 do
      s = s..list[i]..sep
  end
  s = s..list[n]
  _UserListSelection = fn
  editor.AutoCSeparator = string.byte(sep)
  editor:UserListShow(next_user_id,s)
  editor.AutoCSeparator = string.byte(' ')
end

function scite_GetProp(key,default)
   local val = props[key]
   if val and val ~= '' then return val 
   else return default end
end  

function scite_Files(mask)
  local f,path
  if scite_GetProp('PLAT_GTK') then
    f = io.popen('ls -1 '..mask)
  else
    mask = string.gsub(mask,'/','\\')
    local tmpfile = '\\scite_temp1'
    _,_,path = string.find(mask,'(.*\\)')
    local cmd = 'dir /b "'..mask..'" > '..tmpfile
--    print(cmd)
    if Execute then -- scite_other was found!
       Execute(cmd)
    else
      os.execute(cmd)
    end
    f = io.open(tmpfile)
  end
  local files = {}
  if not f then return files end
  for line in f:lines() do
     append(files,path..line)
  end
  f:close()
  return files
end

function scite_FileExists(f)
  local f = io.open(f)
  if not f then return false
  else
    f:close()
    return true
  end
end


-- allows you to bind given Lua functions to shortcut keys
-- without messing around in the properties files!

local function split_two(s,ch)
  local p = string.find(s,ch)
  if p then 
     return string.sub(s,1,p-1),string.sub(s,p+1)
  else
     return s
  end
end

local function split3(s,ch)
  local s1,s2 = split_two(s,ch)
  local s2,s3 = split_two(s2,ch)
  return s1,s2,s3
end

local idx = 10
local shortcuts_used = {}

function scite_Command(tbl)
  if type(tbl) == 'string' then
     tbl = {tbl}
  end
  for i,v in tbl do
     local name,cmd,shortcut = split3(v,'|')
     local which = '.'..idx..'.*'
     props['command.name'..which] = name
     props['command'..which] = cmd     
     props['command.subsystem'..which] = '3'
     props['command.mode'..which] = 'savebefore:no'
     if shortcut then 
       local cmd = shortcuts_used[shortcut]
       if cmd then
          print('Error: shortcut already used in "'..cmd..'"')
       else
      --   print(name,cmd,shortcut)
         props['command.shortcut'..which] = shortcut
         shortcuts_used[shortcut] = name
       end
     end
     idx = idx + 1
  end
end

-- this will quietly fail....

local loaded = {}
local function silent_dofile(f)
 if scite_FileExists(f) then
  f = string.gsub(f,'\\','/')
  --print(f)
  if not loaded[f] then
    dofile(f)
    loaded[f] = true
  else
    --print('already loaded',f)
  end
 end
end

function scite_dofile(f)
 f = props['SciteDefaultHome']..'/'..f
 silent_dofile(f)
end

--scite_dofile 'scite_other.lua'

local path
local lua_dir = scite_GetProp('ext.lua.directory')
--print (lua_dir)
if lua_dir then
  path = lua_dir 
else
  path = props['SciteDefaultHome']..'/scite_lua'
  --print(path)
end

function scite_require(f)
  f = path..'/'..f
  silent_dofile(f)
end

local script_list = scite_Files(path..'/*.lua')
if not script_list then 
  print('Error: no files found in '..path)
else
  for i,file in script_list do
     silent_dofile(file)
  end
end
