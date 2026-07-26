package tree

import (
	"crypto/md5"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// ScanOptions represents options for scanning the file tree
type ScanOptions struct {
	Root           string   // root directory to scan
	MaxDepth       int      // maximum depth to scan (-1 for unlimited)
	ShowHidden     bool     // whether to show hidden files
	IgnorePatterns []string // patterns to ignore (e.g., "node_modules", ".git")
	SortBy         string   // sort method: "name", "size", "modified"
	IncludeGit     bool     // whether to include git information
}

// Scanner scans the file system and builds a tree
type Scanner struct {
	options *ScanOptions
	nodes   []*Node
	stats   *Statistics
	nodeID  int
}

// NewScanner creates a new Scanner
func NewScanner(opts *ScanOptions) *Scanner {
	return &Scanner{
		options: opts,
		nodes:   make([]*Node, 0),
		stats: &Statistics{
			TotalFiles:    0,
			TotalDirs:     0,
			GitModified:   0,
			GitStaged:     0,
			GitUntracked:  0,
			GitConflicted: 0,
		},
		nodeID: 0,
	}
}

// Scan scans the file tree and returns the result
func (s *Scanner) Scan() (*TreeResponse, error) {
	absRoot, err := filepath.Abs(s.options.Root)
	if err != nil {
		return nil, fmt.Errorf("failed to get absolute path: %w", err)
	}

	// Scan the directory tree
	if err := s.scanDirectory(absRoot, "", 0); err != nil {
		return nil, err
	}

	// Sort nodes
	s.sortNodes()

	return &TreeResponse{
		Version: "1.0",
		Root:    absRoot,
		Nodes:   s.nodes,
		Stats:   s.stats,
	}, nil
}

// scanDirectory recursively scans a directory
func (s *Scanner) scanDirectory(path string, parentID string, depth int) error {
	// Check max depth
	if s.options.MaxDepth >= 0 && depth > s.options.MaxDepth {
		return nil
	}

	// Read directory entries
	entries, err := os.ReadDir(path)
	if err != nil {
		// Silently skip directories we can't read (permissions, etc.)
		return nil
	}

	for _, entry := range entries {
		name := entry.Name()

		// Skip hidden files if not showing them
		if !s.options.ShowHidden && strings.HasPrefix(name, ".") {
			continue
		}

		// Check ignore patterns
		if s.shouldIgnore(name) {
			continue
		}

		fullPath := filepath.Join(path, name)
		info, err := entry.Info()
		if err != nil {
			continue // Skip files we can't stat
		}

		// Create node
		node := s.createNode(name, fullPath, info, parentID, depth)
		s.nodes = append(s.nodes, node)

		// Update statistics
		if node.Type == NodeTypeDirectory {
			s.stats.TotalDirs++

			// Recursively scan subdirectory
			if err := s.scanDirectory(fullPath, node.ID, depth+1); err != nil {
				return err
			}
		} else {
			s.stats.TotalFiles++
		}
	}

	return nil
}

// createNode creates a Node from file info
func (s *Scanner) createNode(name, path string, info fs.FileInfo, parentID string, depth int) *Node {
	s.nodeID++
	nodeID := s.generateNodeID(path)

	nodeType := NodeTypeFile
	if info.IsDir() {
		nodeType = NodeTypeDirectory
	} else if info.Mode()&os.ModeSymlink != 0 {
		nodeType = NodeTypeSymlink
	}

	node := &Node{
		ID:       nodeID,
		Name:     name,
		Path:     path,
		Type:     nodeType,
		Depth:    depth,
		ParentID: parentID,
		Metadata: &Metadata{
			Size:        info.Size(),
			Modified:    info.ModTime(),
			Permissions: info.Mode().String(),
			IsHidden:    strings.HasPrefix(name, "."),
		},
		Expanded: false,
	}

	// Count children for directories
	if nodeType == NodeTypeDirectory {
		node.ChildrenCount = s.countChildren(path)
	}

	return node
}

// generateNodeID generates a unique ID for a node based on its path
func (s *Scanner) generateNodeID(path string) string {
	hash := md5.Sum([]byte(path))
	return fmt.Sprintf("%x", hash)[:8]
}

// countChildren counts the number of children in a directory
func (s *Scanner) countChildren(path string) int {
	entries, err := os.ReadDir(path)
	if err != nil {
		return 0
	}

	count := 0
	for _, entry := range entries {
		name := entry.Name()

		// Apply same filters as scanDirectory
		if !s.options.ShowHidden && strings.HasPrefix(name, ".") {
			continue
		}
		if s.shouldIgnore(name) {
			continue
		}
		count++
	}

	return count
}

// shouldIgnore checks if a name matches any ignore pattern
func (s *Scanner) shouldIgnore(name string) bool {
	for _, pattern := range s.options.IgnorePatterns {
		if matched, _ := filepath.Match(pattern, name); matched {
			return true
		}
		// Also check exact match
		if pattern == name {
			return true
		}
	}
	return false
}

// sortNodes sorts the nodes based on the sort option
func (s *Scanner) sortNodes() {
	switch s.options.SortBy {
	case "name":
		sort.Slice(s.nodes, func(i, j int) bool {
			// Directories first, then sort by name
			if s.nodes[i].Type == NodeTypeDirectory && s.nodes[j].Type != NodeTypeDirectory {
				return true
			}
			if s.nodes[i].Type != NodeTypeDirectory && s.nodes[j].Type == NodeTypeDirectory {
				return false
			}
			return strings.ToLower(s.nodes[i].Name) < strings.ToLower(s.nodes[j].Name)
		})
	case "size":
		sort.Slice(s.nodes, func(i, j int) bool {
			return s.nodes[i].Metadata.Size > s.nodes[j].Metadata.Size
		})
	case "modified":
		sort.Slice(s.nodes, func(i, j int) bool {
			return s.nodes[i].Metadata.Modified.After(s.nodes[j].Metadata.Modified)
		})
	default:
		// Default to name sorting
		s.sortNodes()
	}
}

// DefaultIgnorePatterns returns the default patterns to ignore
func DefaultIgnorePatterns() []string {
	return []string{
		".git",
		"node_modules",
		".venv",
		"venv",
		"__pycache__",
		"*.pyc",
		".DS_Store",
		"Thumbs.db",
		"dist",
		"build",
		"target",
		".idea",
		".vscode",
	}
}
