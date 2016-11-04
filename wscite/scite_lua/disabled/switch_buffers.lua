--switch_buffers.lua
--drops down a list of buffers, in recently-used order

scite_Command 'Switch Buffer|do_buffer_list|Ctrl+J'

scite_require 'dlg.lua'
local listbox
if dlg then
  listbox = dlg.listbox()
  scite.AttachExtWindow(listbox:id(),'left','')
end

function insert_listbox(idx,f)
  local _,_,fname = string.find(f,'.*\\(.-)$')
  local idx = listbox:insert(idx,fname)
  listbox:set_data(idx,f)
end

function append_listbox(f)
  insert_listbox(0,f)
end

function OnListDblClick(w)
  local idx = w:get_selection()
  if idx > 0 then
    scite.Open(listbox:get_data(idx))
  end
end

local buffers = {}
local append = table.insert

local function buffer_switch(f)
--- OnOpen() is also called if we move to a new folder
   if string.find(f,'[\\/]$') then return end   
--- swop the new current buffer with the last one!
  local idx  
  for i,file in ipairs(buffers) do
     if file == f then  idx = i; break end
  end
  if idx then 
    table.remove(buffers,idx)
    table.insert(buffers,1,f)
    if listbox then
       print(f,idx)
       listbox:delete(idx)
       insert_listbox(1,f)
    end
  else
    table.insert(buffers,1,f)
    if listbox then
       insert_listbox(1,f)
    end
  end
end

scite_OnOpen(buffer_switch)
scite_OnSwitchFile(buffer_switch)

function do_buffer_list()
     scite_UserListShow(buffers,1,scite.Open)
end
