// Command prready-server is the MCP server entry point.
//
// MCP role: this is the Server process. It communicates via stdio transport
// (stdout carries the MCP protocol, stderr is for logs).
//
// It runs alongside the GitHub MCP server in an editor/IDE host. The AI
// assistant in the host combines data from both servers to produce PR
// readiness reports.
//
// Usage:
//
//	prready-server [--config <path>]
//
// The --config flag specifies the path to the JSON configuration file
// (default: "./.prready.json").
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/user/mcp-pr-readiness/internal/config"
	"github.com/user/mcp-pr-readiness/internal/mcpserver"
)

func main() {
	// CRITICAL: With stdio transport, stdout carries the MCP protocol.
	// All logging MUST go to stderr. A stray stdout write breaks the connection.
	log.SetOutput(os.Stderr)
	log.SetFlags(log.Ltime | log.Lshortfile)

	configPath := flag.String("config", "./.prready.json", "Path to configuration file")
	flag.Parse()

	cfg, err := config.Load(*configPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: %v\n", err)
		os.Exit(1)
	}

	log.Printf("Config loaded: repo=%s base_branch=%s", cfg.RepoPath, cfg.BaseBranch)

	srv := mcpserver.New(cfg)
	if err := srv.Run(context.Background()); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
