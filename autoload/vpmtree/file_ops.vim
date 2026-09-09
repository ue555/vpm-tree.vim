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

def NormalizePath(path: string): string
  return substitute(simplify(fnamemodify(path, ':p')), '/\+$', '', '')
enddef

def BufferRenames(old_path: string, new_path: string): list<dict<any>>
  var old_normalized = NormalizePath(old_path)
  var new_normalized = NormalizePath(new_path)
  var old_prefix = old_normalized .. '/'
  var source_is_directory = isdirectory(old_path)
  var renames: list<dict<any>> = []

  for info in getbufinfo()
    if empty(info.name)
      continue
    endif
    var buffer_path = NormalizePath(info.name)
    var mode = !info.loaded ? 'unloaded'
      : isdirectory(buffer_path) ? 'rename'
      : info.changed ? 'save'
      : 'reload'
    if buffer_path == old_normalized
      renames->add({
        bufnr: info.bufnr,
        path: new_normalized,
        mode: mode,
      })
    elseif source_is_directory && stridx(buffer_path, old_prefix) == 0
      renames->add({
        bufnr: info.bufnr,
        path: new_normalized .. strpart(buffer_path, strlen(old_normalized)),
        mode: mode,
      })
    endif
  endfor

  return renames
enddef

def HasBufferConflict(renames: list<dict<any>>): bool
  var renamed_buffers: dict<bool> = {}
  var target_paths: dict<bool> = {}
  for item in renames
    renamed_buffers[string(item.bufnr)] = true
    target_paths[item.path] = true
  endfor

  for info in getbufinfo()
    if empty(info.name) || has_key(renamed_buffers, string(info.bufnr))
      continue
    endif
    if has_key(target_paths, NormalizePath(info.name))
      return true
    endif
  endfor
  return false
enddef

def BufferChangedExternally(bufnr: number): bool
  v:warningmsg = ''
  execute 'silent checktime ' .. bufnr
  return !empty(v:warningmsg)
enddef

def RenameBuffer(bufnr: number, new_path: string, mode: string): void
  if !bufloaded(bufnr)
    execute 'silent! bwipeout! ' .. bufnr
    return
  endif

  var old_buffer_path = NormalizePath(bufname(bufnr))
  var rename_command = mode == 'save' ? 'silent keepalt saveas! ' : 'silent keepalt file '
  var windows = win_findbuf(bufnr)
  if !empty(windows)
    win_execute(windows[0], rename_command .. fnameescape(new_path))
    if mode == 'reload'
      win_execute(windows[0], 'silent keepalt edit!')
    endif
  else
    var host_winid = FindPromptWinId()
    var original_bufnr = winbufnr(host_winid)
    try
      win_execute(host_winid, printf('silent keepalt noautocmd hide buffer %d', bufnr))
      win_execute(host_winid, rename_command .. fnameescape(new_path))
      if mode == 'reload'
        win_execute(host_winid, 'silent keepalt edit!')
      endif
    finally
      if winbufnr(host_winid) != original_bufnr
        win_execute(host_winid, printf('silent keepalt noautocmd hide buffer %d', original_bufnr))
      endif
    endtry
  endif

  if mode == 'save'
    # :saveas keeps an unloaded alternate buffer for the old path.
    for info in getbufinfo()
      if !empty(info.name) && NormalizePath(info.name) == old_buffer_path
        execute 'silent! bwipeout! ' .. info.bufnr
      endif
    endfor
  endif
enddef

export def RenamePath(old_path: string, new_path: string): bool
  if filereadable(new_path) || isdirectory(new_path)
    echohl ErrorMsg
    echomsg 'File or directory already exists: ' .. fnamemodify(new_path, ':t')
    echohl None
    return false
  endif

  var buffer_renames = BufferRenames(old_path, new_path)
  if HasBufferConflict(buffer_renames)
    echohl ErrorMsg
    echomsg 'A Vim buffer already uses the rename destination'
    echohl None
    return false
  endif

  for item in buffer_renames
    if item.mode == 'save' && BufferChangedExternally(item.bufnr)
      echohl ErrorMsg
      echomsg 'File changed outside Vim; reload or save it before renaming'
      echohl None
      return false
    endif
  endfor

  if rename(old_path, new_path) != 0
    return false
  endif

  for item in buffer_renames
    RenameBuffer(item.bufnr, item.path, item.mode)
  endfor

  return true
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

  # Perform rename
  try
    if RenamePath(old_path, new_path)
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
