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
local re = re or require("re")
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
local qs
qs = function(s)
  local q = tostring(s):gsub('[%"\\]', '\\%0')
  return '"' .. q .. '"'
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
