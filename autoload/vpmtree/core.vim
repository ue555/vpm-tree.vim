vim9script

import './render.vim'
import './buffer.vim'
import './keymap.vim'

# Global state
var tree_bufnr: number = -1
var tree_winnr: number = -1
var tree_data: dict<any> = {}
var current_root: string = ''

# Open the tree
export def Open(): void
  # Get current working directory
  var root = getcwd()

  if tree_bufnr > 0 && bufexists(tree_bufnr)
    # Tree buffer exists, just show it
    buffer.ShowTree(tree_bufnr, tree_winnr)
    tree_winnr = bufwinid(tree_bufnr)
  else
    # Create new tree buffer
    tree_bufnr = buffer.CreateTree()
    tree_winnr = bufwinid(tree_bufnr)

    # Setup keymaps
    keymap.Setup()
  endif

  # Load and render tree
  LoadTree(root)
enddef

# Close the tree
export def Close(): void
  if tree_winnr > 0
    var winid = bufwinid(tree_bufnr)
    if winid > 0
      win_execute(winid, 'close')
    endif
  endif
  tree_winnr = -1
enddef

# Toggle the tree
export def Toggle(): void
  if tree_winnr > 0 && bufwinid(tree_bufnr) > 0
    Close()
  else
    Open()
  endif
enddef

# Refresh the tree
export def Refresh(): void
  if tree_bufnr > 0 && bufexists(tree_bufnr)
    LoadTree(current_root)
  endif
enddef

# Focus the tree window
export def Focus(): void
  if tree_winnr > 0
    var winid = bufwinid(tree_bufnr)
    if winid > 0
      win_gotoid(winid)
    else
      Open()
    endif
  else
    Open()
  endif
enddef

# Find current file in tree
export def FindFile(filepath: string): void
  if !filereadable(filepath)
    return
  endif

  # Open tree if not open
  if tree_winnr <= 0 || bufwinid(tree_bufnr) <= 0
    Open()
  endif

  # TODO: Expand tree to show the file and move cursor to it
  # This would require tracking the tree structure
  echomsg 'Finding: ' .. filepath
enddef

# Load tree data from vpm-tree CLI
def LoadTree(root: string): void
  current_root = root

  # Build command
  var cmd = BuildCommand(root)

  # Execute command and get JSON output
  var output = system(cmd)

  if v:shell_error != 0
    echohl ErrorMsg
    echomsg 'vpm-tree: Failed to load tree: ' .. output
    echohl None
    return
  endif

  # Parse JSON
  try
    tree_data = json_decode(output)

    # Render the tree
    render.Draw(tree_bufnr, tree_data)

  catch
    echohl ErrorMsg
    echomsg 'vpm-tree: Failed to parse tree data: ' .. v:exception
    echohl None
  endtry
enddef

# Build command to execute vpm-tree CLI
def BuildCommand(root: string): string
  var cmd = g:vpm_tree_bin

  cmd ..= ' -root ' .. shellescape(root)

  if g:vpm_tree_max_depth >= 0
    cmd ..= ' -depth ' .. g:vpm_tree_max_depth
  endif

  if g:vpm_tree_show_hidden
    cmd ..= ' -hidden'
  endif

  if !empty(g:vpm_tree_ignore_patterns)
    cmd ..= ' -ignore ' .. shellescape(join(g:vpm_tree_ignore_patterns, ','))
  endif

  cmd ..= ' -sort ' .. g:vpm_tree_sort_by

  if g:vpm_tree_include_git
    cmd ..= ' -git'
  endif

  return cmd
enddef

# Get node at cursor line
export def GetNodeAtLine(lnum: number): dict<any>
  if !has_key(tree_data, 'nodes')
    return {}
  endif

  # Line numbers start from 1, but we need to account for header lines
  # Header is 2 lines (title + separator)
  var node_index = lnum - 3

  if node_index < 0 || node_index >= len(tree_data.nodes)
    return {}
  endif

  return tree_data.nodes[node_index]
enddef

# Open file/directory at cursor
export def OpenAtCursor(): void
  var node = GetNodeAtLine(line('.'))

  if empty(node)
    return
  endif

  if node.type == 'directory'
    # TODO: Expand/collapse directory
    echomsg 'Directory: ' .. node.name
  else
    # Open file in previous window
    var filepath = node.path

    # Go to previous window
    wincmd p

    # Open file
    execute 'edit ' .. fnameescape(filepath)

    # Close tree if auto_close is enabled
    if g:vpm_tree_auto_close
      Close()
    endif
  endif
enddef

# Auto command handler
export def OnBufEnter(): void
  # Auto-refresh on buffer enter (optional)
  # Can be enabled with a config option
enddef

# Get tree buffer number
export def GetTreeBufnr(): number
  return tree_bufnr
enddef

# Check if current window is tree window
export def IsTreeWindow(): bool
  return bufnr('%') == tree_bufnr
enddef
