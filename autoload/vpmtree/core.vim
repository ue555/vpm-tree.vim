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
  redraw
  echo ''
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
  var expanded_paths = GetExpandedPaths()

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
    if has_key(tree_data, 'nodes')
      tree_data.nodes = NormalizeVisibleNodes(tree_data.nodes, expanded_paths)
    endif

    # Render the tree
    render.Draw(tree_bufnr, tree_data)

  catch
    echohl ErrorMsg
    echomsg 'vpm-tree: Failed to parse tree data: ' .. v:exception
    echohl None
  endtry
enddef

def GetExpandedPaths(): list<string>
  var expanded_paths: list<string> = []
  if !has_key(tree_data, 'nodes')
    return expanded_paths
  endif

  for node in tree_data.nodes
    if node.type == 'directory' && get(node, 'expanded', false)
      expanded_paths->add(node.path)
    endif
  endfor

  return expanded_paths
enddef

def AddVisibleNode(node: dict<any>, children_by_parent: dict<any>, visible_nodes: list<dict<any>>): void
  visible_nodes->add(node)

  if node.type != 'directory' || !get(node, 'expanded', false)
    return
  endif

  for child in get(children_by_parent, node.id, [])
    AddVisibleNode(child, children_by_parent, visible_nodes)
  endfor
enddef

def NormalizeVisibleNodes(nodes: list<dict<any>>, expanded_paths: list<string>): list<dict<any>>
  var visible_nodes: list<dict<any>> = []
  var expanded_lookup: dict<bool> = {}
  var root_nodes: list<dict<any>> = []
  var children_by_parent: dict<any> = {}

  for path in expanded_paths
    expanded_lookup[path] = true
  endfor

  for node in nodes
    node.expanded = node.type == 'directory' && has_key(expanded_lookup, node.path)

    var parent_id = get(node, 'parent_id', '')
    if empty(parent_id)
      root_nodes->add(node)
    else
      if !has_key(children_by_parent, parent_id)
        children_by_parent[parent_id] = []
      endif
      add(children_by_parent[parent_id], node)
    endif
  endfor

  for node in root_nodes
    AddVisibleNode(node, children_by_parent, visible_nodes)
  endfor

  return visible_nodes
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
  var node_index = line('.') - 3

  if node_index < 0 || node_index >= len(tree_data.nodes)
    return
  endif

  var node = tree_data.nodes[node_index]

  if node.type == 'directory'
    ToggleDirectory(node_index)
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

# Expand the directory node at the cursor (no-op if already expanded or a file)
export def ExpandAtCursor(): void
  var node_index = line('.') - 3

  if node_index < 0 || node_index >= len(tree_data.nodes)
    return
  endif

  var node = tree_data.nodes[node_index]

  if node.type == 'directory' && !node.expanded
    ToggleDirectory(node_index)
  endif
enddef

# Collapse the directory node at the cursor (no-op if already collapsed or a file)
export def CollapseAtCursor(): void
  var node_index = line('.') - 3

  if node_index < 0 || node_index >= len(tree_data.nodes)
    return
  endif

  var node = tree_data.nodes[node_index]

  if node.type == 'directory' && node.expanded
    ToggleDirectory(node_index)
  endif
enddef

# Expand or collapse the directory node at the given index in tree_data.nodes
def ToggleDirectory(node_index: number): void
  var node = tree_data.nodes[node_index]

  if node.expanded
    # Collapse: drop the contiguous block of descendants that follows it
    # (every node until we hit one back at this depth or shallower)
    var remove_end = node_index + 1
    while remove_end < len(tree_data.nodes) && tree_data.nodes[remove_end].depth > node.depth
      remove_end += 1
    endwhile

    if remove_end > node_index + 1
      remove(tree_data.nodes, node_index + 1, remove_end - 1)
    endif

    node.expanded = false
  else
    # Expand: fetch immediate children and splice them in right after this node
    var children = LoadChildren(node)

    if !empty(children)
      tree_data.nodes = tree_data.nodes[0 : node_index]
        + children
        + tree_data.nodes[node_index + 1 :]
    endif

    node.expanded = true
  endif

  render.Draw(tree_bufnr, tree_data)
enddef

# Load the immediate children of a directory node via the vpm-tree CLI
def LoadChildren(node: dict<any>): list<dict<any>>
  var cmd = BuildCommand(node.path)
  var output = system(cmd)

  if v:shell_error != 0
    echohl ErrorMsg
    echomsg 'vpm-tree: Failed to load children: ' .. output
    echohl None
    return []
  endif

  try
    var data = json_decode(output)
    var children: list<dict<any>> = get(data, 'nodes', [])

    for child in children
      child.depth = node.depth + 1
      child.parent_id = node.id
    endfor

    return children
  catch
    echohl ErrorMsg
    echomsg 'vpm-tree: Failed to parse children: ' .. v:exception
    echohl None
    return []
  endtry
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
