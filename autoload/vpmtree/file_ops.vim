vim9script

import './core.vim'

def FindPromptWinId(): number
  var current_winid = win_getid()
  var tree_bufnr = core.GetTreeBufnr()

  if bufnr('%') != tree_bufnr
    return current_winid
  endif

  for win in getwininfo()
    if win.winid != current_winid && win.bufnr != tree_bufnr
      return win.winid
    endif
  endfor

  return current_winid
enddef

def Prompt(message: string, default_value: string = ''): string
  var tree_winid = win_getid()
  var prompt_winid = FindPromptWinId()
  var result = ''

  if prompt_winid != tree_winid
    win_gotoid(prompt_winid)
  endif

  try
    inputsave()
    result = empty(default_value) ? input(message) : input(message, default_value)
  finally
    inputrestore()
    if win_getid() != tree_winid
      win_gotoid(tree_winid)
    endif
  endtry

  return result
enddef

def ResolvePath(target_path: string, input_path: string): string
  var relative_path = input_path
  var target_name = fnamemodify(target_path, ':t')

  if relative_path =~# '^\.\/'
    relative_path = relative_path[2 :]
  endif

  if !empty(target_name) && relative_path =~# '^' .. escape(target_name, '\.^$~[]') .. '/'
    relative_path = relative_path[len(target_name) + 1 :]
  endif

  return simplify(target_path .. '/' .. relative_path)
enddef

# Create a new file
export def CreateFile(parent_path: string = ''): void
  var target_path = parent_path

  if empty(target_path)
    var node = core.GetNodeAtLine(line('.'))
    if empty(node)
      target_path = getcwd()
    else
      target_path = node.type == 'directory' ? node.path : fnamemodify(node.path, ':h')
    endif
  endif

  var filename = Prompt('Enter file name: ')

  if empty(filename)
    redraw
    echomsg 'File creation cancelled'
    return
  endif

  var filepath = ResolvePath(target_path, filename)

  # Check if file already exists
  if filereadable(filepath) || isdirectory(filepath)
    redraw
    echohl ErrorMsg
    echomsg 'File or directory already exists: ' .. filename
    echohl None
    return
  endif

  # Create the file
  try
    mkdir(fnamemodify(filepath, ':h'), 'p')
    writefile([], filepath)
    redraw
    echomsg 'Created file: ' .. filepath
    core.Refresh()
  catch
    redraw
    echohl ErrorMsg
    echomsg 'Failed to create file: ' .. v:exception
    echohl None
  endtry
enddef

# Create a new directory
export def CreateDirectory(parent_path: string = ''): void
  var target_path = parent_path

  if empty(target_path)
    var node = core.GetNodeAtLine(line('.'))
    if empty(node)
      target_path = getcwd()
    else
      target_path = node.type == 'directory' ? node.path : fnamemodify(node.path, ':h')
    endif
  endif

  var dirname = Prompt('Enter directory name: ')

  if empty(dirname)
    redraw
    echomsg 'Directory creation cancelled'
    return
  endif

  var dirpath = ResolvePath(target_path, dirname)

  # Check if directory already exists
  if isdirectory(dirpath) || filereadable(dirpath)
    redraw
    echohl ErrorMsg
    echomsg 'File or directory already exists: ' .. dirname
    echohl None
    return
  endif

  # Create the directory
  try
    mkdir(dirpath, 'p')
    redraw
    echomsg 'Created directory: ' .. dirpath
    core.Refresh()
  catch
    redraw
    echohl ErrorMsg
    echomsg 'Failed to create directory: ' .. v:exception
    echohl None
  endtry
enddef

# Delete file or directory at cursor
export def Delete(): void
  var node = core.GetNodeAtLine(line('.'))

  if empty(node)
    echohl ErrorMsg
    echomsg 'No file or directory at cursor'
    echohl None
    return
  endif

  var path = node.path
  var type = node.type
  var name = fnamemodify(path, ':t')

  # Confirm deletion
  var msg = type == 'directory'
    ? 'Delete directory "' .. name .. '" and all its contents? (y/n): '
    : 'Delete file "' .. name .. '"? (y/n): '

  var confirm = Prompt(msg)

  redraw

  if confirm !=? 'y' && confirm !=? 'yes'
    echomsg 'Deletion cancelled'
    return
  endif

  # Perform deletion
  try
    if type == 'directory'
      # Delete directory recursively
      var result = delete(path, 'rf')
      if result == 0
        echomsg 'Deleted directory: ' .. name
      else
        echohl ErrorMsg
        echomsg 'Failed to delete directory: ' .. name
        echohl None
        return
      endif
    else
      # Delete file
      var result = delete(path)
      if result == 0
        echomsg 'Deleted file: ' .. name
      else
        echohl ErrorMsg
        echomsg 'Failed to delete file: ' .. name
        echohl None
        return
      endif
    endif

    # Refresh tree
    core.Refresh()
  catch
    echohl ErrorMsg
    echomsg 'Error during deletion: ' .. v:exception
    echohl None
  endtry
enddef

# Rename file or directory at cursor
export def Rename(): void
  var node = core.GetNodeAtLine(line('.'))

  if empty(node)
    echohl ErrorMsg
    echomsg 'No file or directory at cursor'
    echohl None
    return
  endif

  var old_path = node.path
  var old_name = fnamemodify(old_path, ':t')
  var parent_dir = fnamemodify(old_path, ':h')

  var new_name = Prompt('Rename "' .. old_name .. '" to: ', old_name)

  if empty(new_name)
    redraw
    echomsg 'Rename cancelled'
    return
  endif

  if new_name == old_name
    redraw
    echomsg 'Name unchanged'
    return
  endif

  var new_path = parent_dir .. '/' .. new_name

  # Check if target already exists
  if filereadable(new_path) || isdirectory(new_path)
    redraw
    echohl ErrorMsg
    echomsg 'File or directory already exists: ' .. new_name
    echohl None
    return
  endif

  # Perform rename
  try
    var result = rename(old_path, new_path)
    if result == 0
      redraw
      echomsg 'Renamed "' .. old_name .. '" to "' .. new_name .. '"'
      core.Refresh()
    else
      redraw
      echohl ErrorMsg
      echomsg 'Failed to rename: ' .. old_name
      echohl None
    endif
  catch
    redraw
    echohl ErrorMsg
    echomsg 'Error during rename: ' .. v:exception
    echohl None
  endtry
enddef
