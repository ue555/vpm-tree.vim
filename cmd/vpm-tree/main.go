package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/ue555/vpm-tree.vim/pkg/git"
	"github.com/ue555/vpm-tree.vim/pkg/tree"
)

const version = "1.0"

func main() {
	root := flag.String("root", ".", "Root directory to scan")
	depth := flag.Int("depth", -1, "Maximum depth (-1 = unlimited)")
	hidden := flag.Bool("hidden", false, "Show hidden files")
	ignore := flag.String("ignore", "", "Comma-separated ignore patterns")
	sortBy := flag.String("sort", "name", "Sort by: name, size, modified")
	includeGit := flag.Bool("git", true, "Include git information")
	pretty := flag.Bool("pretty", false, "Pretty print JSON output")
	showVersion := flag.Bool("version", false, "Show version")
	flag.Parse()

	if *showVersion {
		fmt.Println("vpm-tree version " + version)
		return
	}

	ignorePatterns := tree.DefaultIgnorePatterns()
	if strings.TrimSpace(*ignore) != "" {
		ignorePatterns = strings.Split(*ignore, ",")
	}

	scanner := tree.NewScanner(&tree.ScanOptions{
		Root:           *root,
		MaxDepth:       *depth,
		ShowHidden:     *hidden,
		IgnorePatterns: ignorePatterns,
		SortBy:         *sortBy,
		IncludeGit:     *includeGit,
	})

	result, err := scanner.Scan()
	if err != nil {
		fmt.Fprintln(os.Stderr, "vpm-tree: error:", err)
		os.Exit(1)
	}

	if *includeGit {
		mgr := git.NewManager(result.Root)
		if err := mgr.UpdateTreeWithGitInfo(result.Nodes, result.Stats); err != nil {
			fmt.Fprintln(os.Stderr, "vpm-tree: git error:", err)
		}
	}

	var out []byte
	if *pretty {
		out, err = json.MarshalIndent(result, "", "  ")
	} else {
		out, err = json.Marshal(result)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "vpm-tree: json error:", err)
		os.Exit(1)
	}

	fmt.Println(string(out))
}
