local function HL(name, val) vim.api.nvim_set_hl(0, name, val) end

vim.g.colors_name = "fallback"
vim.o.background = "dark"

HL("Character", { foreground = "#E1C58D" })
HL("ColorColumn", { background = "#111419", foreground = "#171A20" })
HL("Comment", { foreground = "#515C68" })
HL("Conceal", { foreground = "#1C2228" })
HL("Conditional", { foreground = "#F87070" })
HL("Constant", { foreground = "#FF6666" })
HL("Cursor", { background = "#DFC184", foreground = "#101317" })
HL("CursorColumn", { background = "#191D21" })
HL("CursorLine", { background = "#191D21" })
HL("CursorLineFold", { background = "#101317", foreground = "#70C0BA" })
HL("CursorLineNr", { bold = true, foreground = "#FFE59E" })
HL("CursorLineSign", { background = "#101317" })
HL("Debug", { foreground = "#FB7373" })
HL("Decorator", { foreground = "#FFE59E" })
HL("Define", { foreground = "#C397D8" })
HL("Delimeter", { foreground = "#7AB0DF" })
HL("Delimiter", { foreground = "#FB7373" })
HL("DiagnosticError", { foreground = "#F87070" })
HL("DiagnosticFloatingError", { foreground = "#F87070" })
HL("DiagnosticFloatingHint", { foreground = "#C397D8" })
HL("DiagnosticFloatingInfo", { foreground = "#7AB0DF" })
HL("DiagnosticFloatingWarn", { foreground = "#F97F7F" })
HL("DiagnosticHint", { foreground = "#C397D8" })
HL("DiagnosticInfo", { foreground = "#7AB0DF" })
HL("DiagnosticSignError", { foreground = "#FB7373" })
HL("DiagnosticSignHint", { foreground = "#C397D8" })
HL("DiagnosticSignInfo", { foreground = "#7AB0DF" })
HL("DiagnosticSignWarn", { foreground = "#F97F7F" })
HL("DiagnosticUnderlineError", { foreground = "#F87070" })
HL("DiagnosticUnderlineHint", { foreground = "#C397D8" })
HL("DiagnosticUnderlineInfo", { foreground = "#7AB0DF" })
HL("DiagnosticUnderlineWarn", { foreground = "#F97F7F" })
HL("DiagnosticVirtualTextError", { foreground = "#F87070" })
HL("DiagnosticVirtualTextHint", { foreground = "#C397D8" })
HL("DiagnosticVirtualTextInfo", { foreground = "#7AB0DF" })
HL("DiagnosticVirtualTextWarn", { foreground = "#F97F7F" })
HL("DiagnosticWarn", { foreground = "#F97F7F" })
HL("DiffAdd", { foreground = "#79DCAA", reverse = true })
HL("DiffChange", { foreground = "#C397D8", reverse = true })
HL("DiffDelete", { foreground = "#F87070", reverse = true })
HL("DiffText", { foreground = "#7AB0DF", reverse = true })
HL("Directory", { foreground = "#FFE59E" })
HL("EndOfBuffer", { foreground = "#C397D8" })
HL("Error", { foreground = "#F76262" })
HL("ErrorMsg", { foreground = "#F87070" })
HL("Exception", { foreground = "#36C692" })
HL("Float", { foreground = "#F3A4F1" })
HL("FloatBorder", { background = "#151A1F", foreground = "#151A1F" })
HL("FloatShadow", { background = "#000000", blend = 80 })
HL("FloatShadowThrough", { background = "#000000", blend = 100 })
HL("FocusedSymbol", { background = "#666666", foreground = "#FFA0A0" })
HL("FoldColumn", { background = "#101317", foreground = "#70C0BA" })
HL("Folded", { background = "#101317", foreground = "#282F3C" })
HL("Function", { foreground = "#BE8FD7" })
HL("Identifier", { foreground = "#36C692" })
HL("IncSearch", { background = "#70C0BA", foreground = "#101317" })
HL("InclineNormal", { background = "#151A1F", foreground = "#BABABE" })
HL("InclineNormalNC", { background = "#151A1F", foreground = "#BABABE" })
HL("Include", { bold = true, foreground = "#6AA6DF" })
HL("Italic", { italic = true })
HL("Keyword", { foreground = "#66B3FF" })
HL("Label", { foreground = "#F87070" })
HL("LineNr", { foreground = "#2E3645" })
HL("LineNrAbove", { foreground = "#2E3645" })
HL("LineNrBelow", { foreground = "#2E3645" })
HL("Macro", { foreground = "#F98989" })
HL("MatchBackground", { background = "#111419", foreground = "#171A20" })
HL("MatchParen", { background = "#202530", bold = true })
HL("MatchParenCur", { background = "#202530", bold = true })
HL("MatchWord", { background = "#202530", bold = true })
HL("ModeMsg", { bold = true, foreground = "#7AB0DF" })
HL("MoreMsg", { foreground = "#FFE59E" })
HL("MsgArea", { foreground = "#CACACD" })
HL("MsgSeparator", { foreground = "#C397D8" })
HL("NonText", { foreground = "#222931" })
HL("Normal", { background = "#101317", foreground = "#D4D4D5" })
HL("NormalFloat", { background = "#151A1F", foreground = "#BABABE" })
HL("Number", { foreground = "#54CED6" })
HL("Operator", { foreground = "#70C0BA" })
HL("Pmenu", { background = "#171D20", foreground = "#A0A0A5" })
HL("PmenuSbar", { background = "#171D20", foreground = "#A0A0A5" })
HL("PmenuSel", { background = "#79DCAA", foreground = "#101317" })
HL("PmenuThumb", { background = "#1E2225" })
HL("PreCondit", { foreground = "#F96262" })
HL("PreProc", { foreground = "#F96262" })
HL("Question", { foreground = "#79DCAA" })
HL("QuickFixLine", { background = "#FFE59E", foreground = "#101317" })
HL("RedrawDebugClear", { background = "#FFFF00" })
HL("RedrawDebugComposed", { background = "#008000" })
HL("RedrawDebugNormal", { reverse = true })
HL("RedrawDebugRecompose", { background = "#FF0000" })
HL("Repeat", { foreground = "#B77EE0" })
HL("Search", { background = "#FFE59E", foreground = "#101317" })
HL("SignColumn", { background = "#101317" })
HL("Special", { foreground = "#FB7373" })
HL("SpecialChar", { foreground = "#C397D8" })
HL("SpecialComment", { foreground = "#FFDF8F" })
HL("SpecialKey", { bold = true, foreground = "#FFE59E" })
HL("SpellBad", { foreground = "#F87070" })
HL("SpellCap", { foreground = "#FCCF67" })
HL("SpellLocal", { foreground = "#FB7373" })
HL("SpellRare", { foreground = "#54CED6" })
HL("Statement", { foreground = "#F87070" })
HL("StatusLine", { background = "#101317", foreground = "#7AB0DF" })
HL("StatusLineNC", { foreground = "#7AB0DF" })
HL("StorageClass", { foreground = "#F75858" })
HL("String", { foreground = "#79DCAA" })
HL("Structure", { foreground = "#5FB0FC" })
HL("Substitute", { background = "#B77EE0", foreground = "#101317" })
HL("TabLine", { background = "#101317", bold = true, foreground = "#2C3640" })
HL("TabLineFill", { background = "#101317", foreground = "#7AB0DF" })
HL("TabLineSel", { background = "#7AB0DF", bold = true, foreground = "#101317" })
HL("Tag", { foreground = "#7AB0DF" })
HL("TermCursor", { reverse = true })
HL("Title", { bold = true, foreground = "#4B5259" })
HL("Todo", { foreground = "#FFE59E" })
HL("Type", { foreground = "#F87070" })
HL("Typedef", { foreground = "#C397D8" })
HL("Underlined", { underline = true })
HL("VertSplit", { foreground = "#171C21" })
HL("Visual", { background = "#192023" })
HL("WarningMsg", { foreground = "#FB7373" })
HL("Whitespace", { foreground = "#1E222A" })
HL("WildMenu", { background = "#7AB0DF", foreground = "#101317" })
HL("WinBar", { bold = true })
HL("WinBarNC", { bold = true })
HL("WinSeparator", { foreground = "#171C21" })