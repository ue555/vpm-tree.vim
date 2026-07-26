vim9script

# vpm-tree: A file tree explorer for Vim
# Maintainer: kouji
# License: MIT

if exists('g:loaded_vpm_tree')
  finish
endif
g:loaded_vpm_tree = 1

# Check Vim version
if !has('vim9script')
  echoerr 'vpm-tree requires Vim 9.0 or later with vim9script support'
  finish
endif

# Default configuration
g:vpm_tree_width = get(g:, 'vpm_tree_width', 35)
g:vpm_tree_position = get(g:, 'vpm_tree_position', 'left')  # 'left' or 'right'
g:vpm_tree_show_hidden = get(g:, 'vpm_tree_show_hidden', 0)
g:vpm_tree_max_depth = get(g:, 'vpm_tree_max_depth', 0)
g:vpm_tree_sort_by = get(g:, 'vpm_tree_sort_by', 'name')  # 'name', 'size', 'modified'
g:vpm_tree_ignore_patterns = get(g:, 'vpm_tree_ignore_patterns', [])
g:vpm_tree_include_git = get(g:, 'vpm_tree_include_git', 1)
g:vpm_tree_auto_close = get(g:, 'vpm_tree_auto_close', 1)  # Close tree when opening file

# Path to vpm-tree binary
g:vpm_tree_bin = get(g:, 'vpm_tree_bin', 'vpm-tree')

# Define commands
command! VpmTreeToggle vpmtree#core#Toggle()
command! VpmTreeOpen vpmtree#core#Open()
command! VpmTreeClose vpmtree#core#Close()
command! VpmTreeRefresh vpmtree#core#Refresh()
command! VpmTreeFocus vpmtree#core#Focus()
command! VpmTreeFind vpmtree#core#FindFile(expand('%:p'))

# Define key mappings (user can map these)
nnoremap <silent> <Plug>(vpm-tree-toggle) <ScriptCmd>vpmtree#core#Toggle()<CR>
nnoremap <silent> <Plug>(vpm-tree-open) <ScriptCmd>vpmtree#core#Open()<CR>
nnoremap <silent> <Plug>(vpm-tree-close) <ScriptCmd>vpmtree#core#Close()<CR>
nnoremap <silent> <Plug>(vpm-tree-refresh) <ScriptCmd>vpmtree#core#Refresh()<CR>
nnoremap <silent> <Plug>(vpm-tree-focus) <ScriptCmd>vpmtree#core#Focus()<CR>
nnoremap <silent> <Plug>(vpm-tree-find) <ScriptCmd>vpmtree#core#FindFile(expand('%:p'))<CR>

# Auto commands
augroup VpmTree
  autocmd!
  # Refresh tree when entering a buffer
  autocmd BufEnter * if exists('*vpmtree#core#OnBufEnter') | call vpmtree#core#OnBufEnter() | endif
augroup END
