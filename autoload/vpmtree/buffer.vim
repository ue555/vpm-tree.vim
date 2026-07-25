vim9script

# Create tree buffer
export def CreateTree(): number
  # Create split
  if g:vpm_tree_position == 'left'
    execute 'topleft vertical ' .. g:vpm_tree_width .. 'new'
  else
    execute 'botright vertical ' .. g:vpm_tree_width .. 'new'
  endif

  var bufnr = bufnr('%')

  # Set buffer options
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nobuflisted
  setlocal filetype=vpmtree
  setlocal nowrap
  setlocal cursorline
  setlocal nonumber
  setlocal norelativenumber
  setlocal signcolumn=no
  setlocal foldcolumn=0
  setlocal nomodifiable

  # Set buffer name
  execute 'file VpmTree'

  return bufnr
enddef

# Show existing tree buffer
export def ShowTree(bufnr: number, winnr: number): void
  # Check if already visible
  if bufwinid(bufnr) > 0
    return
  endif

  # Create split and show buffer
  if g:vpm_tree_position == 'left'
    execute 'topleft vertical ' .. g:vpm_tree_width .. 'split'
  else
    execute 'botright vertical ' .. g:vpm_tree_width .. 'split'
  endif

  execute 'buffer ' .. bufnr
enddef
