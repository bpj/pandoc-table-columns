-- Config variables -- feel free to change these
fallback_width = 0.0 -- float
fallback_align = 'AlignDefault' -- see expand_align below!
widths_attr = 'tab-col-widths'
aligns_attr = 'tab-col-aligns'
widths_data_attr = "data-#{widths_attr}"
aligns_data_attr = "data-#{aligns_attr}"

-- One letter abbreviations to official alignment types
expand_align =
  d: 'AlignDefault'
  l: 'AlignLeft'
  c: 'AlignCenter'
  r: 'AlignRight'

-- Save some typing
pdc = assert pandoc, "Cannot find the pandoc library"
unless 'table' == type pdc
  error "Expected variable pandoc to be table"
pdu = assert pandoc.utils, "Cannot find the pandoc.utils library"
-- pdt = assert pandoc.text, "Cannot get the pandoc.text library"
-- jsn = assert pandoc.json, "Cannot get the pandoc.json library"

re or= require"re"

-- pprint = require"moon".p

-- Convert a percentage to a float by dividing it by 100
pcnt2float = (p) -> p / 100


-- re grammar for parsing a (comma/space separated)
-- sequence of substrings into a table of normalized values
-- so for example "50,15*" becomes { 0.5, 0.15, star: '*' }
-- and "lrr" becomes
-- { 'AlignLeft', 'AlignRight', 'AlignRight' }
parse_re = [=[ -- @start-re
  list <- {| (val sep)* val? star? !. |}
  val <- ( %val -> conv )
  sep <- ( %s* %sep %s* )
  star <- {:star: '*' :}
]=]

-- Keys in re definitions which point at subpatterns to compile
re_keys = {'val', 'sep'}

-- Generate an re object with a table of definitions
get_re = (defs) ->
  -- Compile subpatterns
  for k in *re_keys
    defs[k] = re.compile defs[k]
  -- Compile the main pattern
  return re.compile parse_re, defs

-- Parameters for the filter function/generator
filter_defs  = {
  { prop: 'widths'
    attr: widths_attr
    data: widths_data_attr
    re: get_re{val: '[0-9]+', sep: "','", conv: pcnt2float}
    fallbk: fallback_width
  }
  { prop: 'aligns'
    attr: aligns_attr
    data: aligns_data_attr
    re: get_re{val: '[dlcr]', sep: "','?", conv: expand_align}
    fallbk: fallback_align
  }
}

spec_keys = { 'prop', 'fallbk' }

-- Get a list of attribute names
names = {}
for key in *{'attr', 'data'}
  for def in *filter_defs
    names[#names+1] = def[key] if def[key]

-- Generate a table filter to specs
tab_filter = (specs) ->
  -- Generate and return the filter function
  -- as a closure around the specs
  return (complex) -> -- we get a "complex" Table
    -- but it is easier to work on a SimpleTable
    -- although we save any attributes first
    attr = complex.attr
    simple = pdu.to_simple_table complex
    -- Apply each spec
    for spec in *specs
      -- Loop over existing values to get right number
      list = simple[spec.prop]
      for i=1,#list
        -- Set to specified value or default
        list[i] = spec[i] or spec.dft
      simple[spec.prop] = list
    -- Convert back to "complex" table,
    -- restore attributes and return
    complex = pdu.from_simple_table simple
    complex.attr = attr
    return complex

-- Escape/quote a string for display in error message
qs = (s) ->
  q = tostring(s)\gsub '[%"\\]', '\\%0'
  return '"' .. q .. '"'

-- Get the value specs from the attributes
get_specs = (elem) ->
  specs = {} -- collect them here
  -- Loop over the parameters
  for def in *filter_defs
    -- If there is an attribute
    if attr = elem.attributes[def.attr] or elem.attributes[def.data]
      -- and it is valid
      if spec = def.re\match attr
        -- Copy key--val pairs
        spec[k] = def[k] for k in *spec_keys
        -- If there was a star the default value is
        -- the last actual value if any, else the fallback value
        spec.dft = if spec.star then spec[#spec] or def.fallbk else def.fallbk
        -- add these to the specs
        specs[#specs+1] = spec
      else -- if invalid attribute
        error "Invalid #{def.attr}|#{def.data}=#{qs attr}"
  -- If there were any attributes
  if 0 < #specs
    return specs
  -- else if no attributea
  return nil

-- Filter a div
Div = (div) ->
  -- If it has any of the attributes
  if specs = get_specs div
    -- Modify contained tables if any
    div = div\walk Table: tab_filter specs
    -- Should we keep the div?
    return div if div.classes\includes'keep'
    return div.content -- if we shouldn't keep the div
  return nil -- if there were no attributes

-- If the attributes are directly on the table
-- e.g. in djot input
Table = (tab) ->
  -- If it has any of the attributes
  if specs = get_specs tab
    -- Adjust the columns
    tab = tab_filter(specs)(tab)
    -- Should we not keep the attributes?
    unless tab.classes\includes'keep'
      tab.attributes[n] = nil for n in *names
    return tab
  return nil

-- Return the main filter
return { {:Div, :Table} }

