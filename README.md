# `table-columns.lua`

Pandoc filter for setting table column widths explicitly.

## Synopsis

Markdown:

``````markdown
::: {tab-col-widths="25,40,35"}
| foo | bar | baz
|---|---|---
| tic | tac | toc
:::

::: {tab-col-aligns=lrrr}
| | foo | bar | baz
|---|---|---|---
| tic | 1 | 2 | 3
| tac | 10 | 20 | 30
| toc | 100 | 200 | 300
:::

::: {.keep tab-col-widths="20,15*" tab-col-aligns="c*"}
|a|b|g|d
|-|-|-|-
|alpha|beta|gamma|delta
:::
``````

Commandline:

``````sh
pandoc -L table-colums.lua example.md -o example.html
``````

HTML (blank lines added):

``````html
<table>
<colgroup>
<col style="width: 25%" />
<col style="width: 40%" />
<col style="width: 35%" />
</colgroup>
<thead>
<tr>
<th>foo</th>
<th>bar</th>
<th>baz</th>
</tr>
</thead>
<tbody>
<tr>
<td>tic</td>
<td>tac</td>
<td>toc</td>
</tr>
</tbody>
</table>

<table>
<thead>
<tr>
<th style="text-align: left;"></th>
<th style="text-align: right;">foo</th>
<th style="text-align: right;">bar</th>
<th style="text-align: right;">baz</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;">tic</td>
<td style="text-align: right;">1</td>
<td style="text-align: right;">2</td>
<td style="text-align: right;">3</td>
</tr>
<tr>
<td style="text-align: left;">tac</td>
<td style="text-align: right;">10</td>
<td style="text-align: right;">20</td>
<td style="text-align: right;">30</td>
</tr>
<tr>
<td style="text-align: left;">toc</td>
<td style="text-align: right;">100</td>
<td style="text-align: right;">200</td>
<td style="text-align: right;">300</td>
</tr>
</tbody>
</table>

<div class="keep" data-tab-col-widths="20,15*" data-tab-col-aligns="c*">

<table style="width:65%;">
<colgroup>
<col style="width: 20%" />
<col style="width: 15%" />
<col style="width: 15%" />
<col style="width: 15%" />
</colgroup>
<thead>
<tr>
<th style="text-align: center;">a</th>
<th style="text-align: center;">b</th>
<th style="text-align: center;">g</th>
<th style="text-align: center;">d</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: center;">alpha</td>
<td style="text-align: center;">beta</td>
<td style="text-align: center;">gamma</td>
<td style="text-align: center;">delta</td>
</tr>
</tbody>
</table>
</div>
``````

## Rationale

The criteria Pandoc uses to set the column widths of a tables
are somewhat problematic.
If no row in the table in the Markdown source is wider
(in characters) than the value of the `--columns` option
(default: 72) Pandoc will try to determine the relative
widths of the columns from the relative numbers of dashes
for each column in the header separator row.
If no row in the table in the Markdown source is wider
than the value of the `--columns` option the
Markdown reader will set all column widths to zero,
which means that some writers (like the html writer) will
set no explicit column width values in the output, while
some writers will determine the relative widths of the
columns from the relative widths of the contents of the
widest cells in each column.

This is extremely hard to get right in the Markdown source,
so this filter works around it by setting the widths of table
columns according to explicit percentages specified in a
custom attribute on a div which contains the table.
Pandoc's writers will follow these values. 

Similarly Pandoc determines column alignment either
from the alignment of the header/first row content relative
the header separator segment for each column, or from markers
(colons) in the header separator depending on the table type.
At least the first of these two methods is also hard to get
right, and with both of these it is hard to make changes.
For this reason the filter also lets you specify the
alignments of table columns via an attribute on a div.

Finally if you have several consecutive tables which
all should have the same column widths and/or alignments
you can put them all inside the same div, which carries the
width and/or alignment specifications for all of
them. This frees you from having to specify the same widths
and/or alignments on each individual table and makes
it easier to make global changes.

## Usage

Wrap the table(s) in a div with an attribute `tab-col-widths`
and/or `tab-col-aligns` with the specification for widths
and/or alignments as value of each. If either of these
atrributes does not exist the filter will also look for
an attribute
`data-tab-col-widths`
or
`data-tab-col-aligns`.

The value of **`tab-col-widths`** must be
a comma-separated "list" of non-negative integers each
indicating how many percent of the total available width
each of the columns in the table should occupy.^[If the
percentages add up to more than 100 the table will overflow
the available width!]
If there are more percentages than
there are columns in the table the "extra" percentages
will be ignored. If there are fewer percentages than
there are columns in the table the result depends on
whether the last percentage is followed by an asterisk
`*`: if it is the last percentage will be "copied"
to any "extra" columns; if it is not the extra columns will
have their nominal width set to zero, which means that Pandoc
will distribute any remaining width between them as
usual.

The value of **`tab-col-aligns`** must be
a string of optionally comma-separated letters:

| Letter | Alignment
|--------|----------
| `d` | `AlignDefault`
| `l` | `AlignLeft`
| `c` | `AlignCenter`
| `r` | `AlignRight`

Again extra alignments will be ignored if there are more
letters in the string than there are columns in the table
and if there are fewer letters in the string than there
are columns in the table the result depends on whether
there is an `*` after the last letter: if there is the
last actually specified alignment if any will be
"copied" to the extra columns; otherwise the extra columns
will be set to `AlignDefault`.

If the value of any of these attributes doesn't conform
to the descriptions above and is not empty an error will be
thrown.

Unless the wrapping div has a class `.keep` the div will
be replaced with its content,
including any modified tables.

In djot source you can attach the attributes directly to
the table. However if there *also* is a div the div
will take precedence.
If the attributes are attached directly to the table and
there is no class `.keep` the filter will remove any
`tab-col-widths`,
`data-tab-col-widths`,
`tab-col-aligns`
or
`data-tab-col-aligns`
attributes from the table.

## Limitations

This filter only works with simple tables which can be
converted to SimpleTable.


## Source code

The actual source code for this filter,
where you also will find all comments,
is to be found in `table-columns.moon`
and is written in
[MoonScript](https://moonscript.org).
The file you should use as a
filter is `table-columns.lua`, which is generated
automatically with `moonc` which compiles
MoonScript code into Lua code.
While the Lua code produced by `moonc` has its
quirks it is surprisingly readable, but
it preserves neither comments nor spacing.
If you want to hack on the filter I recommend
that you install moonscript with
[luarocks](https://luarocks.org)
(preferably the development version since
that is what I use), work on the MoonScript code
and and compile it with
`moonc table-columns.moon`
when you are done.
Patches or pull requests which modify the
automatically generated Lua code will not be
accepted!

## Copyright and License

This software is Copyright (c) 2024 by Benct Philip Jonsson.

This is free software, licensed under:

  The MIT (X11) License

http://www.opensource.org/licenses/mit-license.php