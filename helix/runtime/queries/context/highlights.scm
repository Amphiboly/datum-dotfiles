; ~/.config/helix/runtime/queries/context/highlights.scm
;
; highlights.scm for tree-sitter-context

(text) @user.text
(title_setting (value (value_brace_group (value_brace_group_text) @user.text)))

(command_name) @command.name

(settings_block) @command.set
(option_block) @command.set

(line_comment) @comment

(escaped) @escaped

(inline_math) @math
