vim9script

# Draw the tree in the buffer
export def Draw(bufnr: number, tree_data: dict<any>): void
  if !bufexists(bufnr)
    return
  endif

  var lines: list<string> = []

  # Header
  var root_name = fnamemodify(tree_data.root, ':~')
  lines->add(' VPM Tree: ' .. root_name)
  lines->add(repeat('─', g:vpm_tree_width - 1))

  # Render nodes
  if has_key(tree_data, 'nodes')
    for node in tree_data.nodes
      lines->add(RenderNode(node))
    endfor
  endif

  # Footer with statistics
  if has_key(tree_data, 'stats')
    lines->add('')
    lines->add(RenderStats(tree_data.stats))
  endif

  # Write to buffer
  setbufvar(bufnr, '&modifiable', 1)
  deletebufline(bufnr, 1, '$')
  setbufline(bufnr, 1, lines)
  setbufvar(bufnr, '&modifiable', 0)

  # Apply highlighting
  ApplyHighlights(bufnr)
enddef

# Render a single node
def RenderNode(node: dict<any>): string
  var indent = repeat('  ', node.depth)
  var icon = GetIcon(node)
  var git_icon = GetGitIcon(node)
  var name = node.name

  # Add trailing slash for directories
  if node.type == 'directory'
    name ..= '/'
  endif

  return git_icon .. ' ' .. indent .. icon .. ' ' .. name
enddef

# Get icon for node type
def GetIcon(node: dict<any>): string
  if node.type == 'directory'
    if has_key(node, 'expanded') && node.expanded
      return '▼'
    else
      return '▶'
    endif
  elseif node.type == 'symlink'
    return '🔗'
  else
    # File icon based on extension
    var ext = fnamemodify(node.name, ':e')
    return GetFileIcon(ext)
  endif
enddef

# Get file icon based on extension
def GetFileIcon(ext: string): string
  var icons = {
    'vim': '󰈔',
    'lua': '',
    'py': '',
    'js': '',
    'ts': '',
    'go': '',
    'rs': '',
    'md': '',
    'json': '',
    'yml': '',
    'yaml': '',
    'toml': '',
    'txt': '',
    'sh': '',
  }

  return get(icons, ext, '')
enddef

# Get git status icon
def GetGitIcon(node: dict<any>): string
  if !has_key(node, 'git') || node.git == null
    return '   '
  endif

  var git = node.git
  var status = git.status

  if git.conflict
    return '[C]'
  elseif status == 'added'
    return '[A]'
  elseif status == 'modified'
    return '[M]'
  elseif status == 'deleted'
    return '[D]'
  elseif status == 'renamed'
    return '[R]'
  elseif status == 'untracked'
    return '[?]'
  else
    return '   '
  endif
enddef

# Render statistics
def RenderStats(stats: dict<any>): string
  var parts: list<string> = []

  parts->add(printf('Files: %d', stats.total_files))
  parts->add(printf('Dirs: %d', stats.total_dirs))

  if stats.git_modified > 0
    parts->add(printf('Modified: %d', stats.git_modified))
  endif

  if stats.git_staged > 0
    parts->add(printf('Staged: %d', stats.git_staged))
  endif

  return ' ' .. join(parts, ' | ')
enddef

# Apply syntax highlighting
def ApplyHighlights(bufnr: number): void
  win_execute(bufwinid(bufnr), 'syntax clear')

  # Header
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeHeader /^ VPM Tree:.*/')
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeSeparator /^─\+/')

  # Icons
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeDirIcon /▶\|▼/')
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeFileIcon /\|🔗/')

  # Git status
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeGitModified /\[M\]/')
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeGitAdded /\[A\]/')
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeGitDeleted /\[D\]/')
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeGitUntracked /\[?\]/')
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeGitConflict /\[C\]/')

  # Directory names (end with /)
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeDirectory /[^/]\+\/$/')

  # Statistics
  win_execute(bufwinid(bufnr), 'syntax match VpmTreeStats /^ Files:.*/')

  # Define highlight groups
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeHeader Title')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeSeparator Comment')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeDirIcon Directory')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeFileIcon Normal')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeDirectory Directory')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeGitModified WarningMsg')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeGitAdded DiffAdd')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeGitDeleted DiffDelete')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeGitUntracked Comment')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeGitConflict ErrorMsg')
  win_execute(bufwinid(bufnr), 'highlight default link VpmTreeStats Comment')
enddef
