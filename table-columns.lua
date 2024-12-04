
-- Do NOT edit. Automatically generated from table-columns.moon
-- See README.md at 
-- https://github.com/bpj/pandoc-table-columns

local fallback_width = 0.0
local fallback_align = 'AlignDefault'
local widths_attr = 'tab-col-widths'
local aligns_attr = 'tab-col-aligns'
local widths_data_attr = "data-" .. tostring(widths_attr)
local aligns_data_attr = "data-" .. tostring(aligns_attr)
local expand_align = {
  d = 'AlignDefault',
  l = 'AlignLeft',
  c = 'AlignCenter',
  r = 'AlignRight'
}
local pdc = assert(pandoc, "Cannot find the pandoc library")
if not ('table' == type(pdc)) then
  error("Expected variable pandoc to be table")
end
local pdu = assert(pandoc.utils, "Cannot find the pandoc.utils library")
local lpeg = lpeg or require("lpeg")
local re = re or require("re")
local utfR = assert(lpeg.utfR, 'Cannot find lpeg.utfR. Please update pandoc!')
local char, code
do
  local _obj_0 = utf8
  char, code = _obj_0.char, _obj_0.codepoint
end
local y = lpeg.utfR(0x00, 0x10ffff)
local esc = {
  ["\""] = '\\"',
  ["\\"] = '\\\\',
  ["\a"] = '\\a',
  ["\b"] = '\\b',
  ["\f"] = '\\f',
  ["\n"] = '\\n',
  ["\r"] = '\\r',
  ["\t"] = '\\t',
  ["\v"] = '\\v'
}
local lang = os.getenv('LANG') or os.getenv('LC_ALL') or ""
local have_utf8 = lang:match('UTF%-8')
local want_esc
local _exp_0 = os.getenv('PDC_TAB_COLS_ESC')
if '1' == _exp_0 or 1 == _exp_0 or 'true' == _exp_0 then
  want_esc = true
elseif nil == _exp_0 or '0' == _exp_0 or 0 == _exp_0 or 'false' == _exp_0 or "" == _exp_0 then
  want_esc = false
else
  want_esc = error("Cannot use env var PDC_TAB_COLS_ESC as boolean")
end
if want_esc or not have_utf8 then
  for i = 0x20, 0x7e do
    local c = char(i)
    local _update_0 = c
    esc[_update_0] = esc[_update_0] or c
  end
  setmetatable(esc, {
    __index = function(self, c)
      return ("\\u{%x}"):format(code(c))
    end
  })
else
  local _list_0 = {
    {
      0,
      0x1f
    },
    {
      0x7f,
      0x9f
    }
  }
  for _index_0 = 1, #_list_0 do
    local range = _list_0[_index_0]
    for _des_0 in range do
      local s, e
      s, e = _des_0[1], _des_0[2]
      for i = s, e do
        local _update_0 = char(i)
        esc[_update_0] = esc[_update_0] or ("\\u{%x}"):format(i)
      end
    end
  end
end
local qpat = re.compile([=[ -- @start-re
    str <- {~ dq char^-30 trail? dq !. ~}
    -- Nothing becomes a quote
    dq <- ( "" -> '"' )
    -- A possibly escaped char or a stray byte
    char <- ( %w / %y -> esc / . )
    -- An ellipsis for the rest
    trail <- ( .+ -> '...' )
  ]=], {
  y = y,
  esc = esc
})
local qs
qs = function(s)
  return qpat:match(tostring(s))
end
local pcnt2float
pcnt2float = function(p)
  return p / 100
end
local parse_re = [=[ -- @start-re
  list <- {| (val sep)* val? star? !. |}
  val <- ( %val -> conv )
  sep <- ( %s* ','? %s* )
  star <- {:star: '*' :}
]=]
local re_keys = {
  'val'
}
local get_re
get_re = function(defs)
  for _index_0 = 1, #re_keys do
    local k = re_keys[_index_0]
    defs[k] = re.compile(defs[k])
  end
  return re.compile(parse_re, defs)
end
local filter_defs = {
  {
    prop = 'widths',
    attr = widths_attr,
    data = widths_data_attr,
    re = get_re({
      val = '[0-9]+',
      conv = pcnt2float
    }),
    fallbk = fallback_width
  },
  {
    prop = 'aligns',
    attr = aligns_attr,
    data = aligns_data_attr,
    re = get_re({
      val = '[dlcr]',
      conv = expand_align
    }),
    fallbk = fallback_align
  }
}
local spec_keys = {
  'prop',
  'fallbk'
}
local names = { }
local _list_0 = {
  'attr',
  'data'
}
for _index_0 = 1, #_list_0 do
  local key = _list_0[_index_0]
  for _index_1 = 1, #filter_defs do
    local def = filter_defs[_index_1]
    if def[key] then
      names[#names + 1] = def[key]
    end
  end
end
local tab_filter
tab_filter = function(specs)
  return function(complex)
    local attr = complex.attr
    local simple = pdu.to_simple_table(complex)
    for _index_0 = 1, #specs do
      local spec = specs[_index_0]
      local list = simple[spec.prop]
      for i = 1, #list do
        list[i] = spec[i] or spec.dft
      end
      simple[spec.prop] = list
    end
    complex = pdu.from_simple_table(simple)
    complex.attr = attr
    return complex
  end
end
local get_specs
get_specs = function(elem)
  local specs = { }
  for _index_0 = 1, #filter_defs do
    local def = filter_defs[_index_0]
    do
      local attr = elem.attributes[def.attr] or elem.attributes[def.data]
      if attr then
        do
          local spec = def.re:match(attr)
          if spec then
            if 0 < #spec then
              for _index_1 = 1, #spec_keys do
                local k = spec_keys[_index_1]
                spec[k] = def[k]
              end
              if spec.star then
                spec.dft = spec[#spec] or def.fallbk
              else
                spec.dft = def.fallbk
              end
              specs[#specs + 1] = spec
            end
          else
            error("Invalid " .. tostring(def.attr) .. "|" .. tostring(def.data) .. "=" .. tostring(qs(attr)))
          end
        end
      end
    end
  end
  if 0 < #specs then
    return specs
  end
  return nil
end
local Div
Div = function(div)
  do
    local specs = get_specs(div)
    if specs then
      div = div:walk({
        Table = tab_filter(specs)
      })
      if div.classes:includes('keep') then
        return div
      end
      return div.content
    end
  end
  return nil
end
local Table
Table = function(tab)
  do
    local specs = get_specs(tab)
    if specs then
      tab = tab_filter(specs)(tab)
      if not (tab.classes:includes('keep')) then
        for _index_0 = 1, #names do
          local n = names[_index_0]
          tab.attributes[n] = nil
        end
      end
      return tab
    end
  end
  return nil
end
return {
  {
    Div = Div,
    Table = Table
  }
}
