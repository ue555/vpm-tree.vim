package tree

import "time"

// NodeType represents the type of a tree node
type NodeType string

const (
	NodeTypeFile      NodeType = "file"
	NodeTypeDirectory NodeType = "directory"
	NodeTypeSymlink   NodeType = "symlink"
)

// GitStatus represents git status information
type GitStatus struct {
	Status     string `json:"status"`      // modified, added, deleted, untracked, etc.
	Staged     bool   `json:"staged"`      // whether changes are staged
	Untracked  bool   `json:"untracked"`   // whether file is untracked
	Additions  int    `json:"additions"`   // number of added lines
	Deletions  int    `json:"deletions"`   // number of deleted lines
	Conflict   bool   `json:"conflict"`    // whether file has conflicts
}

// Metadata represents file/directory metadata
type Metadata struct {
	Size        int64     `json:"size"`        // file size in bytes
	Modified    time.Time `json:"modified"`    // last modified time
	Permissions string    `json:"permissions"` // file permissions (e.g., "-rw-r--r--")
	IsHidden    bool      `json:"is_hidden"`   // whether file/dir is hidden
}

// Node represents a node in the file tree
type Node struct {
	ID            string     `json:"id"`             // unique identifier
	Name          string     `json:"name"`           // file/directory name
	Path          string     `json:"path"`           // absolute path
	Type          NodeType   `json:"type"`           // file, directory, or symlink
	Depth         int        `json:"depth"`          // depth in the tree
	ParentID      string     `json:"parent_id,omitempty"` // parent node ID
	ChildrenCount int        `json:"children_count"` // number of children (for directories)
	Git           *GitStatus `json:"git,omitempty"`  // git status information
	Metadata      *Metadata  `json:"metadata"`       // file metadata
	Expanded      bool       `json:"expanded"`       // whether directory is expanded
}

// TreeResponse represents the complete tree structure response
type TreeResponse struct {
	Version string      `json:"version"` // API version
	Root    string      `json:"root"`    // root path
	Nodes   []*Node     `json:"nodes"`   // list of nodes
	Stats   *Statistics `json:"stats"`   // tree statistics
}

// Statistics represents tree statistics
type Statistics struct {
	TotalFiles    int `json:"total_files"`    // total number of files
	TotalDirs     int `json:"total_dirs"`     // total number of directories
	GitModified   int `json:"git_modified"`   // number of modified files
	GitStaged     int `json:"git_staged"`     // number of staged files
	GitUntracked  int `json:"git_untracked"`  // number of untracked files
	GitConflicted int `json:"git_conflicted"` // number of conflicted files
}
