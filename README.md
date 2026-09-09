# vpm-tree.vim

A blazing-fast file tree explorer for Vim, powered by Golang.

## Name Origin

**vpm-tree.vim** combines:
- **vpm** = **V**im **P**ackage **M**anager (the parent project)
- **tree** = File tree explorer
- **.vim** = Vim plugin naming convention

## ✨ Features

- ⚡ **Blazing Fast** - Golang CLI for high-performance file scanning
- 🎯 **Git Integration** - Show git status, staged files, conflicts
- 🚀 **Large Projects** - Optimized for large codebases
- 🎨 **Beautiful UI** - Icons, colors, and clean interface
- ⌨️ **Vim9script** - Modern Vim9script plugin
- 🔧 **Configurable** - Extensive customization options
- 💪 **Lightweight** - Minimal memory footprint
- 📝 **File Operations** - Create, delete, and rename files/directories directly from the tree

## Architecture

```
┌────────────────────────────────┐
│   Vim 9.0+ (Editor)           │
│   ┌────────────────────────┐  │
│   │ vpm-tree.vim           │  │
│   │ (Vim9script Plugin)    │  │
│   └───────┬────────────────┘  │
│           │ JSON              │
└───────────┼───────────────────┘
            ↓
┌───────────────────────────────┐
│ vpm-tree CLI (Golang)         │
│ - File Scanning              │
│ - Git Information            │
│ - JSON Output                │
└───────────────────────────────┘
```

## Requirements

- **Vim** >= 9.0 (with vim9script support)
- **Go** >= 1.25 (for building; compatible through Go 1.27)
- **Git** >= 2.19.0 (optional, for git features)

## Installation

### Method 1: Using vpm (Recommended)

If you're using [vpm](https://github.com/ue555/vpm) (Vim Package Manager):

#### 1. Add to your plugins configuration

Add to `~/.config/vpm/plugins.json`:

**Option 1: Using install script (easiest, no sudo required)**
```json
{
  "plugins": [
    {
      "url": "ue555/vpm-tree.vim",
      "build": "bash install.sh"
    }
  ]
}
```

**Option 2: Using make install-local (no sudo required)**
```json
{
  "plugins": [
    {
      "url": "ue555/vpm-tree.vim",
      "build": "make install-local"
    }
  ]
}
```

**Option 3: Install to /usr/local/bin (requires sudo)**
```json
{
  "plugins": [
    {
      "url": "ue555/vpm-tree.vim",
      "build": "make install"
    }
  ]
}
```

#### 2. Install

```bash
vpm -config ~/.config/vpm/plugins.json -cmd install
```

This will:
1. Clone the repository to `~/.vim/pack/vpm/start/vpm-tree.vim/`
2. Build the `vpm-tree` CLI binary
3. Install binary and Vim plugin automatically

**Important**: Add `~/.local/bin` to your PATH if using Option 1 or 2:

For **Bash** users, add to `~/.bashrc`:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

For **Zsh** users, add to `~/.zshrc`:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify the PATH is set:
```bash
which vpm-tree
```

### Method 2: Build from Source (Recommended)

```bash
# Clone repository
git clone https://github.com/ue555/vpm-tree.vim.git
cd vpm-tree.vim

# Run installation script (easiest)
./install.sh

# Or use make (requires sudo for /usr/local/bin)
make install

# Or install to ~/.local/bin (no sudo required)
make install-local
```

This will:
1. Build the `vpm-tree` CLI binary
2. Install binary to `/usr/local/bin/` or `~/.local/bin/`
3. Install Vim plugin to `~/.vim/pack/vpm-tree/start/vpm-tree.vim/`

### Method 3: Manual Installation

#### 1. Build CLI Binary

```bash
# Build
go build -o bin/vpm-tree ./cmd/vpm-tree

# Install binary
sudo cp bin/vpm-tree /usr/local/bin/
```

#### 2. Install Vim Plugin

```bash
# Create plugin directory
mkdir -p ~/.vim/pack/vpm-tree/start/vpm-tree.vim

# Copy plugin files
cp -r plugin autoload ~/.vim/pack/vpm-tree/start/vpm-tree.vim/
```

### Method 4: Using vim-plug

```vim
Plug 'ue555/vpm-tree.vim', { 'do': 'bash install.sh' }
```

**Note**: The installation script will automatically build and install the binary. If you prefer manual installation:

```bash
cd ~/.vim/plugged/vpm-tree.vim

# Option 1: Use install script
./install.sh

# Option 2: Use make with sudo
sudo make install

# Option 3: Install to ~/.local/bin (no sudo)
make install-local
```

## Usage

### Basic Commands

```vim
" Toggle tree
:VpmTreeToggle

" Open tree
:VpmTreeOpen

" Close tree
:VpmTreeClose

" Refresh tree
:VpmTreeRefresh

" Find current file in tree
:VpmTreeFind
```

### Key Mappings

Inside the tree window:

| Key | Action |
|-----|--------|
| `<CR>`, `o` | Open file/directory |
| `l` | Expand directory |
| `h` | Collapse directory |
| `<Space>`, `za` | Toggle expand/collapse |
| `a` | Create new file |
| `A` | Create new directory |
| `d` | Delete file/directory |
| `r` | Rename file/directory |
| `R`, `<F5>` | Refresh tree |
| `q` | Close tree |
| `j/k` | Navigate up/down |
| `-`, `u` | Go to parent directory |
| `C` | Change root to current directory |
| `?` | Show help |

### File Operations

vpm-tree.vim supports common file operations directly from the tree:

#### Create File (`a`)
Press `a` to create a new file in the current directory (or parent directory if cursor is on a file).
You will be prompted to enter the filename.

#### Create Directory (`A`)
Press `A` to create a new directory in the current directory (or parent directory if cursor is on a file).
You will be prompted to enter the directory name.

#### Delete (`d`)
Press `d` to delete the file or directory at cursor. You will be asked to confirm the deletion.
For directories, all contents will be deleted recursively.

#### Rename (`r`)
Press `r` to rename the file or directory at cursor. You will be prompted to enter the new name.

### Recommended Key Mappings

Add to your `~/.vimrc` or `~/.vim/vimrc`:

```vim
" Toggle tree with ]e
nnoremap ]e :VpmTreeToggle<CR>

" Or use Ctrl-n
nmap <C-n> <Plug>(vpm-tree-toggle)

" Find current file with Leader-f
nmap <Leader>f <Plug>(vpm-tree-find)
```

## Configuration

### Default Settings

```vim
" Tree width
let g:vpm_tree_width = 35

" Tree position: 'left' or 'right'
let g:vpm_tree_position = 'left'

" Show hidden files
let g:vpm_tree_show_hidden = 0

" Maximum depth (-1 for unlimited, 0 for root only, 1 for one level, etc.)
let g:vpm_tree_max_depth = -1

" Sort by: 'name', 'size', or 'modified'
let g:vpm_tree_sort_by = 'name'

" Include git information
let g:vpm_tree_include_git = 1

" Auto close tree when opening file
let g:vpm_tree_auto_close = 1

" Ignore patterns
let g:vpm_tree_ignore_patterns = []

" Path to vpm-tree binary
let g:vpm_tree_bin = 'vpm-tree'
```

### Example Configuration

```vim
" ~/.vimrc or ~/.vim/vimrc

" Wider tree
let g:vpm_tree_width = 40

" Show hidden files
let g:vpm_tree_show_hidden = 1

" Additional ignore patterns
let g:vpm_tree_ignore_patterns = ['*.tmp', '*.bak', 'vendor']

" Key mappings
nmap <C-n> <Plug>(vpm-tree-toggle)
nmap <Leader>f <Plug>(vpm-tree-find)
```

## CLI Usage

The `vpm-tree` CLI can be used independently:

```bash
# Scan current directory
vpm-tree

# Scan specific directory with pretty JSON
vpm-tree -root /path/to/project -pretty

# Limit depth
vpm-tree -depth 3

# Show hidden files
vpm-tree -hidden

# Disable git integration
vpm-tree -git=false

# Custom ignore patterns
vpm-tree -ignore "node_modules,dist,build"

# Sort by size
vpm-tree -sort size
```

### CLI Options

| Option | Default | Description |
|--------|---------|-------------|
| `-root` | `.` | Root directory to scan |
| `-depth` | `-1` | Maximum depth (-1 = unlimited) |
| `-hidden` | `false` | Show hidden files |
| `-ignore` | (defaults) | Comma-separated ignore patterns |
| `-sort` | `name` | Sort by: name, size, modified |
| `-git` | `true` | Include git information |
| `-pretty` | `false` | Pretty print JSON output |
| `-version` | - | Show version |

## JSON Output Format

```json
{
  "version": "1.0",
  "root": "/path/to/project",
  "nodes": [
    {
      "id": "abc123",
      "name": "src",
      "path": "/path/to/project/src",
      "type": "directory",
      "depth": 0,
      "children_count": 5,
      "git": {
        "status": "modified",
        "staged": false,
        "additions": 10,
        "deletions": 2
      },
      "metadata": {
        "size": 4096,
        "modified": "2024-01-15T10:30:00Z",
        "permissions": "drwxr-xr-x"
      }
    }
  ],
  "stats": {
    "total_files": 150,
    "total_dirs": 25,
    "git_modified": 5,
    "git_staged": 3
  }
}
```

## Git Integration

vpm-tree provides rich git integration:

- **[M]** - Modified files
- **[A]** - Added files
- **[D]** - Deleted files
- **[R]** - Renamed files
- **[?]** - Untracked files
- **[C]** - Conflicted files

Git information includes:
- Status (modified, added, deleted, etc.)
- Staged/unstaged
- Line additions/deletions
- Conflict detection

## Performance

Optimized for large projects:

- **Concurrent scanning** - Fast directory traversal
- **Smart caching** - Reduced redundant operations
- **Efficient JSON** - Minimal data transfer
- **On-demand loading** - Only scan when needed

Benchmark (10,000 files):
- Tree scan: ~100ms
- Git status: ~200ms
- Total: ~300ms

## Development

```bash
# Format code
make fmt

# Run tests
make test

# Build
make build

# Run example
make example
```

## Comparison

### vs NERDTree
- ⚡ 10x faster (Golang vs VimScript)
- 🎯 Better git integration
- 💪 Handles large projects better

### vs nvim-tree.lua
- ✅ Works with Vim (not just Neovim)
- ⚡ Faster git operations
- 🔧 Simpler architecture

## Troubleshooting

### Binary not found

```vim
" Specify binary path
let g:vpm_tree_bin = '/path/to/vpm-tree'
```

### Git information not showing

```bash
# Check git availability
which git

# Check repository status
cd /path/to/project
git status
```

### Tree not opening

```vim
" Check Vim version
:version

" Ensure Vim 9.0+ with vim9script
:echo has('vim9script')
```

## License

MIT License

## Acknowledgments

Inspired by:
- [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)
- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [NERDTree](https://github.com/preservim/nerdtree)

## Related Projects

- [vpm](https://github.com/ue555/vpm) - Vim Package Manager
- [nvpm](https://github.com/ue555/nvpm) - Neovim Package Manager
