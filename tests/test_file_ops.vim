vim9script

set rtp^=.

import '../autoload/vpmtree/file_ops.vim' as ops

var root = tempname()
mkdir(root, 'p')
var old_path = root .. '/old.txt'
var new_path = root .. '/new.txt'
writefile(['saved content'], old_path)

execute 'edit ' .. fnameescape(old_path)
setline(1, 'modified content')
assert_true(&modified)

assert_true(ops.RenamePath(old_path, new_path))
assert_equal(new_path, expand('%:p'))
assert_false(filereadable(old_path))
assert_equal(['modified content'], readfile(new_path))
assert_false(&modified)
assert_equal(-1, bufnr(old_path))

setline(1, 'modified after rename')
write
assert_false(filereadable(old_path))
assert_equal(['modified after rename'], readfile(new_path))

bwipe!

var unloaded_old_path = root .. '/unloaded-old.txt'
var unloaded_new_path = root .. '/unloaded-new.txt'
writefile(['preserved content'], unloaded_old_path)
execute 'edit ' .. fnameescape(unloaded_old_path)
bdelete
assert_false(bufloaded(unloaded_old_path))
assert_true(ops.RenamePath(unloaded_old_path, unloaded_new_path))
assert_false(filereadable(unloaded_old_path))
assert_equal(['preserved content'], readfile(unloaded_new_path))
assert_equal(-1, bufnr(unloaded_old_path))

var external_old_path = root .. '/external-old.txt'
var external_new_path = root .. '/external-new.txt'
writefile(['original'], external_old_path)
execute 'edit ' .. fnameescape(external_old_path)
setline(1, 'buffer edit')
writefile(['external edit with a different size'], external_old_path)
assert_false(ops.RenamePath(external_old_path, external_new_path))
assert_equal(['external edit with a different size'], readfile(external_old_path))
assert_false(filereadable(external_new_path))
bwipe!

var reloaded_old_path = root .. '/reloaded-old.txt'
var reloaded_new_path = root .. '/reloaded-new.txt'
writefile(['original'], reloaded_old_path)
execute 'edit ' .. fnameescape(reloaded_old_path)
writefile(['external edit'], reloaded_old_path)
assert_true(ops.RenamePath(reloaded_old_path, reloaded_new_path))
assert_equal(reloaded_new_path, expand('%:p'))
assert_equal(['external edit'], getline(1, '$'))
assert_equal(['external edit'], readfile(reloaded_new_path))
bwipe!

var old_directory = root .. '/old-directory'
var new_directory = root .. '/new-directory'
mkdir(old_directory)
mkdir(old_directory .. '/nested')
enew
execute 'file ' .. fnameescape(old_directory)
new
execute 'file ' .. fnameescape(old_directory .. '/nested')
assert_true(ops.RenamePath(old_directory, new_directory))
assert_false(isdirectory(old_directory))
assert_true(isdirectory(new_directory))
assert_equal(new_directory .. '/nested', substitute(expand('%:p'), '/\+$', '', ''))
bwipe!
execute 'buffer ' .. bufnr(new_directory)
assert_equal(new_directory, substitute(expand('%:p'), '/\+$', '', ''))
bwipe!

delete(root, 'rf')

if !empty(v:errors)
  writefile(v:errors, '/tmp/vpm-tree-test-errors')
  cquit
endif

echomsg 'vpm-tree file operation tests passed'
qa!
