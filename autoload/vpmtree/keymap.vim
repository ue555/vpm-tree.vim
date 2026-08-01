vim9script

import './core.vim'
import './file_ops.vim' as ops

# Setup key mappings for tree buffer
export def Setup(): void
  # Open file/directory
  nnoremap <buffer> <silent> <CR> <ScriptCmd>core.OpenAtCursor()<CR>
  nnoremap <buffer> <silent> o <ScriptCmd>core.OpenAtCursor()<CR>

  # Expand/collapse directory (fern.vim-style: l expands, h collapses)
  nnoremap <buffer> <silent> l <ScriptCmd>core.ExpandAtCursor()<CR>
  nnoremap <buffer> <silent> h <ScriptCmd>core.CollapseAtCursor()<CR>

  # Toggle expand/collapse directory
  nnoremap <buffer> <silent> <Space> <ScriptCmd>core.OpenAtCursor()<CR>
  nnoremap <buffer> <silent> za <ScriptCmd>core.OpenAtCursor()<CR>

  # File operations
  nnoremap <buffer> <silent> a <ScriptCmd>CreateFile()<CR>
  nnoremap <buffer> <silent> A <ScriptCmd>CreateDirectory()<CR>
  nnoremap <buffer> <silent> d <ScriptCmd>Delete()<CR>
  nnoremap <buffer> <silent> r <ScriptCmd>Rename()<CR>

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

# Wrapper functions for file operations
def CreateFile(): void
  ops.CreateFile()
enddef

def CreateDirectory(): void
  ops.CreateDirectory()
enddef

def Delete(): void
  ops.Delete()
enddef

def Rename(): void
  ops.Rename()
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
    '<CR>, o    - Open file/directory (toggle expand/collapse on dirs)',
    'l         - Expand directory',
    'h         - Collapse directory',
    '<Space>   - Toggle expand/collapse',
    '',
    'a         - Create new file',
    'A         - Create new directory',
    'd         - Delete file/directory',
    'r         - Rename file/directory',
    '',
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
