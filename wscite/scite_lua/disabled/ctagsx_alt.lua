-- browse a tags database from SciTE!
-- Set this property:
-- ctags.path.cxx=<full path to tags file>
-- (e.g. assuming ctags was run in e:\scite\src, then
-- ctags.path.cxx=e:\scite\src\tags)
-- Version 0.8; This requires extman. 
-- 1. Doesn't need to shell out to readtags, which is
-- slow on old machines.  Instead, the tags file is
-- read in by Lua on startup.  
-- 2. Multiple tags are handled correctly; a drop-down
-- list is presented
-- 3. Alt+C followed by t allows you to explicitly type in
-- the name of a tag;  Alt+C followed by f allows you
-- to specify a regular expression.
-- 4. There is a full stack of marks available.

scite_Command {
   'Find ctag|find_ctag $(CurrentWord)|Ctrl+.',
   'Go to mark|goto_mark|Alt+.',
   'Set Mark|set_mark|Ctrl+\'',
   'Select from mark|select_mark|Ctrl+/',
   'Alt-C|do_altc_commands|Alt+C',
}
    
  local operation

  local function handle_line(l)
     editor:EndUndoAction()
     editor:Undo()
     scite_OnEditorLine(handle_line,'remove')
     -- payload!
     if operation then operation(l) end
     operation = nil
  end

  function do_altc_commands()
    editor:BeginUndoAction()
    scite_OnChar('once',function (ch)
       editor:EndUndoAction()
       editor:Undo()
       editor:BeginUndoAction()
       if ch == 't' then
          operation = function(s)
             find_ctag(s,false)
          end
       elseif ch == 'f' then
          operation = function(s)
             find_ctag(s,true)
          end
       end
       scite_OnEditorLine(handle_line)
       return true
    end)
  end

local gMarkStack = {}
local sizeof = table.getn
local push = table.insert
local pop = table.remove
local top = function(s) return s[sizeof(s)] end

-- this centers the cursor position
-- easy enough to make it optional!
local function center_pos(line)
  if not line then 
     line = editor:LineFromPosition(editor.CurrentPos)
  end
  local top = editor.FirstVisibleLine
  local middle = top + editor.LinesOnScreen/2
  editor:LineScroll(0,line - middle)
end

local function open_file(file,line,was_pos)
  scite.Open(file)
  if not was_pos then 
    editor:GotoLine(line)
    center_pos(line)
  else
    editor:GotoPos(line)
    center_pos()
  end
end

function set_mark()
  push(gMarkStack,{file=props['FilePath'],pos=editor.CurrentPos})
end

function goto_mark()
 local mark = pop(gMarkStack)
 if mark then 
    open_file(mark.file,mark.pos,true)
 end   
end  

function select_mark()
local mark = top(gMarkStart)
if mark then 
    local p1 = editor:PositionFromLine(mark.line)
    local p2 = editor.CurrentPos
    editor:SetSel(p1,p2)
 end   
end

local find = string.find

local function extract_path(path)
-- given a full path, find the directory part
 local s1,s2 = find(path,'/[^/]+$')
 if not s1 then -- try backslashes!
    s1,s2 = find(path,'\\[^\\]+$')
 end
 if s1 then 
    return string.sub(path,1,s1-1)
 else
    return nil
 end
end

local function ReadTagFile(file)
  local f = io.open(file)
  if not f then return nil end
  local tags = {}
  -- skip comment section
  local l = f:read()
  while find(l,'^!') do l = f:read() end
  -- now we can pick up the tags!
  for line in f:lines() do
    local _,_,tag = find(line,'^([^\t]+)\t')
    _,_,tag = find(tag,'([A-Za-z_][A-Za-z_0-9]*)') --strip any whitespace off the tag.
    local existing_line = tags[tag]
    if not existing_line then 
        tags[tag] = line..'@'
    else
        tags[tag] = existing_line..'@'..line
    end
  end
  return tags
end

local gTagFile = props['ctags.path.cxx']
local tags = ReadTagFile(gTagFile)

local function OpenTag(tag)
  -- ask SciTE to open the file
  local file_name = tag.file
  local path = extract_path(gTagFile)
  if path then file_name = path..'/'..file_name end
  set_mark()
  scite.Open(file_name)
  -- depending on what kind of tag, either search for the pattern,
  -- or go to the line.
  local pattern = tag.pattern
  if type(pattern) == 'string' then
    local p1 = editor:findtext(pattern)
    if p1 then 
       editor:GotoPos(p1)
       center_pos()
    end
  else
    local tag_line = pattern
    editor:GotoLine(tag_line)
    center_pos(tag_line)
  end
end

 
function find_ctag(f,partial)
  local result
  if partial then
    result = ''
    for tag,val in tags do
       if find(tag,f) then
         result = result..val..'@'
       end
    end
  else
    result = tags[f]
  end
  if not result then return end  -- not found  
  local matches = {}
  local k = 0;
  for line in string.gfind(result,'([^@]+)@') do
    k = k + 1
    -- split this into the three tab-separated fields
    -- _extended_ ctags format ends in ;"
    local s1,s2,tag_name,file_name,tag_pattern = find(line, '([^\t]*)\t([^\t]*)\t(.*);\"')
        s1 = find(tag_pattern,'$*/$')
    if s1 ~= nil then 
      tag_pattern = string.sub(tag_pattern,3,s1-1) 
      tag_pattern = string.gsub(tag_pattern,'\\/','/')    
      matches[k] = {tag=f,file=file_name,pattern=tag_pattern}
    else
      local tag_line = tonumber(tag_pattern)
      matches[k] = {tag=f,file=file_name,pattern=tag_line}
    end
    matches[k].pattern = string.gsub(matches[k].pattern, '\t', ' ')
  end

  if k == 0 then return end
  if k > 1 then -- multiple tags found
    local list = {}
    for i,t in ipairs(matches) do
      table.insert(list,i..' '..t.pattern..' '..t.file)
    end
    scite_UserListShow(list,1,function(s)
       local _,_,tok = find(s,'^(%d+)')
       local idx = tonumber(tok) -- very important!
       OpenTag(matches[idx])
     end)
  else
    OpenTag(matches[1])
  end  
end


