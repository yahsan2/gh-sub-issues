package cmd

import (
	"github.com/spf13/cobra"
)

var addCmd = &cobra.Command{
	Use:   "add <parent-issue> <sub-issue>",
	Short: "Add an existing issue as a sub-issue to a parent issue",
	Long:  `Link an existing issue to a parent issue using GitHub's issue hierarchy feature.`,
	Args:  cobra.ExactArgs(2),
	RunE: func(cmd *cobra.Command, args []string) error {
		// Implementation will be added in next tasks
		return nil
	},
}

func init() {
	// Add command to root
	rootCmd.AddCommand(addCmd)
	
	// Add flags (will be implemented in next tasks)
}