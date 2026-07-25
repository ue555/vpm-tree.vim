vim9script

import './core.vim'

# Setup key mappings for tree buffer
export def Setup(): void
  # Open file/directory
  nnoremap <buffer> <silent> <CR> <ScriptCmd>core.OpenAtCursor()<CR>
  nnoremap <buffer> <silent> o <ScriptCmd>core.OpenAtCursor()<CR>

  # Expand/collapse directory
  nnoremap <buffer> <silent> <Space> <ScriptCmd>ToggleNode()<CR>
  nnoremap <buffer> <silent> za <ScriptCmd>ToggleNode()<CR>

  # Refresh tree
  nnoremap <buffer> <silent> R <ScriptCmd>core.Refresh()<CR>
  nnoremap <buffer> <silent> <F5> <ScriptCmd>core.Refresh()<CR>

  # Close tree
  nnoremap <buffer> <silent> q <ScriptCmd>core.Close()<CR>

  # Navigation
  nnoremap <buffer> <silent> j j
  nnoremap <buffer> <silent> k k
  nnoremap <buffer> <silent> gg gg
  nnoremap <buffer> <silent> G G

  # Go to parent directory
  nnoremap <buffer> <silent> - <ScriptCmd>GoToParent()<CR>
  nnoremap <buffer> <silent> u <ScriptCmd>GoToParent()<CR>

  # Change root to current directory
  nnoremap <buffer> <silent> C <ScriptCmd>ChangeRoot()<CR>

  # Help
  nnoremap <buffer> <silent> ? <ScriptCmd>ShowHelp()<CR>
enddef

# Toggle expand/collapse for directory
def ToggleNode(): void
  var node = core.GetNodeAtLine(line('.'))

  if empty(node) || node.type != 'directory'
    return
  endif

  # TODO: Implement expand/collapse logic
  echomsg 'Toggle: ' .. node.name
enddef

# Go to parent directory
def GoToParent(): void
  # TODO: Implement parent directory navigation
  echomsg 'Go to parent directory'
enddef

# Change root to current directory
def ChangeRoot(): void
  var node = core.GetNodeAtLine(line('.'))

  if empty(node)
    return
  endif

  if node.type == 'directory'
    execute 'cd ' .. fnameescape(node.path)
    core.Refresh()
  else
    echomsg 'Not a directory'
  endif
enddef

# Show help
def ShowHelp(): void
  var help_lines = [
    'VPM Tree Key Bindings:',
    '',
    '<CR>, o    - Open file/directory',
    '<Space>   - Toggle expand/collapse',
    'R, <F5>   - Refresh tree',
    'q         - Close tree',
    'j/k       - Navigate up/down',
    '-,u       - Go to parent directory',
    'C         - Change root to current directory',
    '?         - Show this help',
  ]

  echohl Title
  echo join(help_lines, "\n")
  echohl None
enddef
