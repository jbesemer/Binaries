scite_Command {
    'Complete Declaration|complete_declaration()|Ctrl+d'
}

function complete_declaration()
    local line = editor:GetCurLine()
    -- fetch the first non-blank token on the line
    local s1,s2,classname = string.find(line,'%s*([^%s]+)')
    if not s1 then return end
    local init = ' = new '..classname
    -- if it ends with ']', then we don't have to make it a constructor call
    local was_array = string.sub(classname,-1) == ']'
    if not was_array then
        init = init..'()'
    end
    init = init..';'
    -- this will leave the cursor at the end of the inserted text
    editor:AddText(init)
    -- generally, people are going to have to specify a size for the array
    -- so put the cursor inside the []
    if was_array then
        editor:CharLeft();
        editor:CharLeft();
    end
end

local template = [[
using System;
using System.Collections;

public class $List : CollectionBase {
    public int Add($ s) {
        return List.Add(s);
    }
    
    public void Remove($ s) {
        List.Remove(s);
    }
    
    public $ this[int i] {
        get { return ($)(List[i]); }
    }
    
    public $[] AsArray() {
        $[] arr = new $[List.Count];
        List.CopyTo(arr,0);
        return arr;
    }
}
]]

function list(type)
  local classname = type..'List'
  local filename = classname..'.cs'
  -- does this class already exist?
  local f = io.open(filename,'r')
  if f then
     f:close()
     print(filename..' already exists')
     return
  end

  local body = string.gsub(template,'%$',type);
  local f = io.open(filename,'w')
  f:write(body)
  f:close()
  return ''
end

scite_require 'macro.lua'

add_macro 'list(name)=$list(name)'

local filename
function set_filename(f)
  filename = f
end

scite_OnSwitchFile(set_filename)
scite_OnOpen(set_filename)

function current_line_number()
    return editor:LineFromPosition(editor.CurrentPos)+1
end

function note(msg)
  local comment = '//*note '..os.date('%d/%m/%y')..' '.. os.getenv("USERNAME")..':'..msg
  local f = io.open('comments.txt','a')
  f:write(comment..'\n')
  f:write(filename..':'..current_line_number()..'\n')
  f:close()
  return comment
end

add_macro 'note(msg)=$note(msg)'

function Prop(type,var)
  local first_char = string.sub(var,1,1)
  first_char = string.upper(first_char)
  local prop_name = first_char..string.sub(var,2)
  local text = [[
    $type $var;
    
    public $type $prop_name {
        get { return $var; }
        set { $var = value; }
    }
  ]]
  local gsub = string.gsub
  text = gsub(text,"$type",type)
  text = gsub(text,"$var",var)
  text = gsub(text,"$prop_name",prop_name)
  return text
end

add_macro 'prop(type,var)=$Prop(type,var)'



