package git

import (
	"bufio"
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"

	"github.com/ue555/vpm-tree.vim/pkg/tree"
)

// Manager manages git operations
type Manager struct {
	rootPath   string
	statusMap  map[string]*tree.GitStatus
	mu         sync.RWMutex
	isGitRepo  bool
}

// NewManager creates a new Git Manager
func NewManager(rootPath string) *Manager {
	mgr := &Manager{
		rootPath:  rootPath,
		statusMap: make(map[string]*tree.GitStatus),
	}

	// Check if this is a git repository
	mgr.isGitRepo = mgr.checkIsGitRepo()

	return mgr
}

// checkIsGitRepo checks if the path is inside a git repository
func (m *Manager) checkIsGitRepo() bool {
	cmd := exec.Command("git", "-C", m.rootPath, "rev-parse", "--is-inside-work-tree")
	err := cmd.Run()
	return err == nil
}

// IsGitRepo returns whether the path is a git repository
func (m *Manager) IsGitRepo() bool {
	return m.isGitRepo
}

// LoadStatus loads git status for all files in the repository
func (m *Manager) LoadStatus() error {
	if !m.isGitRepo {
		return nil
	}

	// Run git status --porcelain
	cmd := exec.Command("git", "-C", m.rootPath, "status", "--porcelain", "-uall")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("git status failed: %w", err)
	}

	// Parse output
	m.mu.Lock()
	defer m.mu.Unlock()

	scanner := bufio.NewScanner(strings.NewReader(string(output)))
	for scanner.Scan() {
		line := scanner.Text()
		if len(line) < 4 {
			continue
		}

		statusCode := line[0:2]
		filePath := line[3:]

		// Convert to absolute path
		absPath := filepath.Join(m.rootPath, filePath)

		status := m.parseStatusCode(statusCode)
		m.statusMap[absPath] = status
	}

	return scanner.Err()
}

// parseStatusCode parses git status code into GitStatus
func (m *Manager) parseStatusCode(code string) *tree.GitStatus {
	status := &tree.GitStatus{
		Staged:    false,
		Untracked: false,
		Conflict:  false,
	}

	stagedCode := code[0:1]
	unstagedCode := code[1:2]

	// Parse staged status
	switch stagedCode {
	case "M":
		status.Status = "modified"
		status.Staged = true
	case "A":
		status.Status = "added"
		status.Staged = true
	case "D":
		status.Status = "deleted"
		status.Staged = true
	case "R":
		status.Status = "renamed"
		status.Staged = true
	case "C":
		status.Status = "copied"
		status.Staged = true
	case "U":
		status.Status = "updated"
		status.Conflict = true
	}

	// Parse unstaged status
	if unstagedCode != " " && unstagedCode != "?" {
		switch unstagedCode {
		case "M":
			if status.Status == "" {
				status.Status = "modified"
			}
		case "D":
			if status.Status == "" {
				status.Status = "deleted"
			}
		case "U":
			status.Conflict = true
		}
	}

	// Handle untracked files
	if code == "??" {
		status.Status = "untracked"
		status.Untracked = true
	}

	// If no specific status, default to clean
	if status.Status == "" {
		status.Status = "clean"
	}

	return status
}

// GetStatus returns git status for a specific path
func (m *Manager) GetStatus(path string) *tree.GitStatus {
	if !m.isGitRepo {
		return nil
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	// Check exact match first
	if status, ok := m.statusMap[path]; ok {
		return status
	}

	// Check if any children have status (for directories)
	for p, status := range m.statusMap {
		if strings.HasPrefix(p, path+string(filepath.Separator)) {
			// Directory has modified children
			return &tree.GitStatus{
				Status: "modified",
				Staged: status.Staged,
			}
		}
	}

	return nil
}

// GetDiffStats gets diff statistics for a file
func (m *Manager) GetDiffStats(path string) (additions, deletions int, err error) {
	if !m.isGitRepo {
		return 0, 0, nil
	}

	relPath, err := filepath.Rel(m.rootPath, path)
	if err != nil {
		return 0, 0, err
	}

	// Get diff stats
	cmd := exec.Command("git", "-C", m.rootPath, "diff", "--numstat", "HEAD", "--", relPath)
	output, err := cmd.Output()
	if err != nil {
		// File might not be committed yet, try diff against index
		cmd = exec.Command("git", "-C", m.rootPath, "diff", "--numstat", "--cached", "--", relPath)
		output, err = cmd.Output()
		if err != nil {
			return 0, 0, nil // Not an error, just no diff
		}
	}

	// Parse numstat output
	if len(output) > 0 {
		parts := strings.Fields(string(output))
		if len(parts) >= 2 {
			fmt.Sscanf(parts[0], "%d", &additions)
			fmt.Sscanf(parts[1], "%d", &deletions)
		}
	}

	return additions, deletions, nil
}

// UpdateTreeWithGitInfo updates tree nodes with git information
func (m *Manager) UpdateTreeWithGitInfo(nodes []*tree.Node, stats *tree.Statistics) error {
	if !m.isGitRepo {
		return nil
	}

	// Load all git status
	if err := m.LoadStatus(); err != nil {
		return err
	}

	// Update each node
	for _, node := range nodes {
		gitStatus := m.GetStatus(node.Path)
		if gitStatus != nil {
			node.Git = gitStatus

			// Get diff stats for files
			if node.Type == tree.NodeTypeFile && gitStatus.Status != "clean" {
				additions, deletions, _ := m.GetDiffStats(node.Path)
				node.Git.Additions = additions
				node.Git.Deletions = deletions
			}

			// Update statistics
			if gitStatus.Status == "modified" || gitStatus.Status == "added" || gitStatus.Status == "deleted" {
				stats.GitModified++
			}
			if gitStatus.Staged {
				stats.GitStaged++
			}
			if gitStatus.Untracked {
				stats.GitUntracked++
			}
			if gitStatus.Conflict {
				stats.GitConflicted++
			}
		}
	}

	return nil
}
