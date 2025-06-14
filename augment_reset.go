package main

import (
	"bufio"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

// Config structures for different JSON files
type StateConfig struct {
	DeviceID               string                 `json:"deviceId"`
	UserID                 string                 `json:"userId"`
	Email                  string                 `json:"email"`
	TrialStartDate         string                 `json:"trialStartDate"`
	TrialEndDate           string                 `json:"trialEndDate"`
	TrialDuration          int                    `json:"trialDuration"`
	TrialStatus            string                 `json:"trialStatus"`
	TrialExpired           bool                   `json:"trialExpired"`
	TrialRemainingDays     int                    `json:"trialRemainingDays"`
	TrialCount             int                    `json:"trialCount"`
	UsageCount             int                    `json:"usageCount"`
	TotalUsageCount        int                    `json:"totalUsageCount"`
	LastUsageDate          *string                `json:"lastUsageDate"`
	MessageCount           int                    `json:"messageCount"`
	TotalMessageCount      int                    `json:"totalMessageCount"`
	LastReset              string                 `json:"lastReset"`
	FirstRunDate           string                 `json:"firstRunDate"`
	LastRunDate            string                 `json:"lastRunDate"`
	SessionID              string                 `json:"sessionId"`
	LastSessionDate        *string                `json:"lastSessionDate"`
	SessionHistory         []interface{}          `json:"sessionHistory"`
	IsFirstRun             bool                   `json:"isFirstRun"`
	HasCompletedOnboarding bool                   `json:"hasCompletedOnboarding"`
	HasUsedTrial           bool                   `json:"hasUsedTrial"`
	Preferences            map[string]interface{} `json:"preferences"`
	Tracking               map[string]interface{} `json:"tracking"`
}

type SubscriptionConfig struct {
	Status         string        `json:"status"`
	Type           string        `json:"type"`
	StartDate      string        `json:"startDate"`
	EndDate        string        `json:"endDate"`
	IsActive       bool          `json:"isActive"`
	IsExpired      bool          `json:"isExpired"`
	RemainingDays  int           `json:"remainingDays"`
	TrialCount     int           `json:"trialCount"`
	LastTrialReset *string       `json:"lastTrialReset"`
	PreviousTrials []interface{} `json:"previousTrials"`
}

type AccountConfig struct {
	UserID        string        `json:"userId"`
	Email         string        `json:"email"`
	DeviceID      string        `json:"deviceId"`
	CreatedAt     string        `json:"createdAt"`
	LastLogin     string        `json:"lastLogin"`
	IsActive      bool          `json:"isActive"`
	TrialHistory  []interface{} `json:"trialHistory"`
	DeviceHistory []interface{} `json:"deviceHistory"`
}

// waitForKeypress waits for user input before exiting
func waitForKeypress() {
	if runtime.GOOS == "windows" && os.Getenv("TERM") == "" {
		fmt.Println("\nPress Enter to exit...")
	} else {
		fmt.Println("\nPress Enter to exit...")
	}

	reader := bufio.NewReader(os.Stdin)
	reader.ReadLine()
}

// isEditorRunning checks if VS Code or Cursor is currently running
func isEditorRunning() bool {
	var cmd *exec.Cmd

	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("tasklist", "/FI", "IMAGENAME eq Code.exe", "/FI", "IMAGENAME eq Cursor.exe")
	case "darwin":
		cmd = exec.Command("sh", "-c", "pgrep -x 'Code' || pgrep -x 'Cursor' || pgrep -x 'Code Helper' || pgrep -x 'Cursor Helper'")
	case "linux":
		cmd = exec.Command("sh", "-c", "pgrep -x 'code' || pgrep -x 'cursor' || pgrep -x 'Code' || pgrep -x 'Cursor'")
	default:
		return false
	}

	output, err := cmd.Output()
	if err != nil {
		return false
	}

	result := strings.ToLower(string(output))
	if runtime.GOOS == "windows" {
		return strings.Contains(result, "code.exe") || strings.Contains(result, "cursor.exe")
	}
	return len(strings.TrimSpace(string(output))) > 0
}

// killEditorProcess attempts to close running VS Code or Cursor processes
func killEditorProcess() bool {
	var cmd *exec.Cmd

	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("cmd", "/C", "taskkill /F /IM Code.exe /T & taskkill /F /IM Cursor.exe /T")
	case "darwin":
		cmd = exec.Command("sh", "-c", "pkill -9 'Code' & pkill -9 'Cursor'")
	case "linux":
		cmd = exec.Command("sh", "-c", "pkill -9 'code' & pkill -9 'cursor'")
	default:
		return false
	}

	err := cmd.Run()
	if err != nil {
		fmt.Printf("Error closing editors: %v\n", err)
		return false
	}

	// Wait for processes to close
	time.Sleep(1500 * time.Millisecond)

	return !isEditorRunning()
}

// formatTimestamp formats a time to a timestamp string
func formatTimestamp(t time.Time) string {
	return t.Format("20060102150405000")
}

// backupFile creates a backup of the specified file
func backupFile(filePath string) (string, error) {
	timestamp := formatTimestamp(time.Now())
	backupPath := fmt.Sprintf("%s.%s.bak", filePath, timestamp)

	sourceFile, err := os.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("backup failed: %v", err)
	}
	defer sourceFile.Close()

	destFile, err := os.Create(backupPath)
	if err != nil {
		return "", fmt.Errorf("backup failed: %v", err)
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	if err != nil {
		return "", fmt.Errorf("backup failed: %v", err)
	}

	return backupPath, nil
}

// getAugmentConfigPaths returns all possible Augment configuration file paths
func getAugmentConfigPaths() []string {
	var paths []string
	homeDir, _ := os.UserHomeDir()

	editors := []string{"Code", "Cursor"}
	configFiles := []string{"state.json", "subscription.json", "account.json"}
	cacheDirs := []string{"Cache", "CachedData"}

	switch runtime.GOOS {
	case "windows":
		appData := os.Getenv("APPDATA")
		localAppData := os.Getenv("LOCALAPPDATA")

		// Main configuration files
		for _, editor := range editors {
			for _, configFile := range configFiles {
				paths = append(paths, filepath.Join(appData, editor, "User", "globalStorage", "augment.augment", configFile))
			}
		}

		// Cache directories
		for _, editor := range editors {
			for _, cacheDir := range cacheDirs {
				paths = append(paths, filepath.Join(appData, editor, cacheDir, "augment.augment"))
			}
			paths = append(paths, filepath.Join(localAppData, editor, "User", "globalStorage", "augment.augment"))
		}

	case "darwin":
		// Main configuration files
		for _, editor := range editors {
			for _, configFile := range configFiles {
				paths = append(paths, filepath.Join(homeDir, "Library", "Application Support", editor, "User", "globalStorage", "augment.augment", configFile))
			}
		}

		// Cache directories
		for _, editor := range editors {
			paths = append(paths, filepath.Join(homeDir, "Library", "Caches", editor, "augment.augment"))
			paths = append(paths, filepath.Join(homeDir, "Library", "Application Support", editor, "Cache", "augment.augment"))
		}

	case "linux":
		// Main configuration files
		for _, editor := range editors {
			for _, configFile := range configFiles {
				paths = append(paths, filepath.Join(homeDir, ".config", editor, "User", "globalStorage", "augment.augment", configFile))
			}
		}

		// Cache directories
		for _, editor := range editors {
			paths = append(paths, filepath.Join(homeDir, ".cache", editor, "augment.augment"))
			paths = append(paths, filepath.Join(homeDir, ".config", editor, "Cache", "augment.augment"))
		}
	}

	return paths
}

// generateDeviceID generates a random device ID
func generateDeviceID() string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// generateUserID generates a random user ID
func generateUserID() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// generateSessionID generates a random session ID
func generateSessionID() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// generateEmail generates a random email address
func generateEmail() string {
	bytes := make([]byte, 8)
	rand.Read(bytes)
	randomString := hex.EncodeToString(bytes)
	return fmt.Sprintf("user_%s@example.com", randomString)
}

// createStateConfig creates a new state configuration
func createStateConfig(deviceID, userID, email string, trialStart, trialEnd time.Time) *StateConfig {
	now := time.Now()
	return &StateConfig{
		DeviceID:               deviceID,
		UserID:                 userID,
		Email:                  email,
		TrialStartDate:         trialStart.Format(time.RFC3339),
		TrialEndDate:           trialEnd.Format(time.RFC3339),
		TrialDuration:          14,
		TrialStatus:            "active",
		TrialExpired:           false,
		TrialRemainingDays:     14,
		TrialCount:             0,
		UsageCount:             0,
		TotalUsageCount:        0,
		LastUsageDate:          nil,
		MessageCount:           0,
		TotalMessageCount:      0,
		LastReset:              now.Format(time.RFC3339),
		FirstRunDate:           now.Format(time.RFC3339),
		LastRunDate:            now.Format(time.RFC3339),
		SessionID:              generateSessionID(),
		LastSessionDate:        nil,
		SessionHistory:         []interface{}{},
		IsFirstRun:             true,
		HasCompletedOnboarding: false,
		HasUsedTrial:           false,
		Preferences: map[string]interface{}{
			"theme":         "light",
			"language":      "en",
			"notifications": true,
		},
		Tracking: map[string]interface{}{
			"lastCheck":      nil,
			"checkCount":     0,
			"lastValidation": nil,
		},
	}
}

// createSubscriptionConfig creates a new subscription configuration
func createSubscriptionConfig(trialStart, trialEnd time.Time) *SubscriptionConfig {
	return &SubscriptionConfig{
		Status:         "active",
		Type:           "trial",
		StartDate:      trialStart.Format(time.RFC3339),
		EndDate:        trialEnd.Format(time.RFC3339),
		IsActive:       true,
		IsExpired:      false,
		RemainingDays:  14,
		TrialCount:     0,
		LastTrialReset: nil,
		PreviousTrials: []interface{}{},
	}
}

// createAccountConfig creates a new account configuration
func createAccountConfig(deviceID, userID, email string, trialStart time.Time) *AccountConfig {
	return &AccountConfig{
		UserID:        userID,
		Email:         email,
		DeviceID:      deviceID,
		CreatedAt:     trialStart.Format(time.RFC3339),
		LastLogin:     trialStart.Format(time.RFC3339),
		IsActive:      true,
		TrialHistory:  []interface{}{},
		DeviceHistory: []interface{}{},
	}
}

// resetAugmentTrial performs the main reset operation
func resetAugmentTrial() error {
	fmt.Println("🔍 Checking for running editors...")
	if isEditorRunning() {
		fmt.Println("⚠️ VS Code or Cursor is running, attempting to close...")
		if killEditorProcess() {
			fmt.Println("✅ Editors have been closed\n")
		} else {
			fmt.Println("❌ Failed to close editors")
			return fmt.Errorf("failed to close editors")
		}
	}

	configPaths := getAugmentConfigPaths()
	fmt.Printf("📂 Found %d configuration paths\n", len(configPaths))

	// Generate new account data
	fmt.Println("🎲 Generating new account data...")
	newDeviceID := generateDeviceID()
	newUserID := generateUserID()
	userEmail := generateEmail()
	fmt.Println("✅ New account data generated successfully\n")

	// Calculate trial dates
	trialStartDate := time.Now()
	trialEndDate := trialStartDate.AddDate(0, 0, 14)

	var processedCount, errorCount int

	for _, configPath := range configPaths {
		fmt.Printf("\n🔄 Processing: %s\n", configPath)

		// Create directory if it doesn't exist
		if err := os.MkdirAll(filepath.Dir(configPath), 0755); err != nil {
			fmt.Printf("❌ Error creating directory: %v\n", err)
			errorCount++
			continue
		}

		// Backup existing config
		fmt.Println("💾 Backing up configuration...")
		if _, err := os.Stat(configPath); err == nil {
			if backupPath, err := backupFile(configPath); err == nil {
				fmt.Printf("✅ Configuration backup complete: %s\n", backupPath)
			} else {
				fmt.Printf("⚠️ Backup failed: %v\n", err)
			}
		} else {
			fmt.Println("ℹ️ No existing configuration to backup")
		}

		// Check if it's a directory and remove it
		if info, err := os.Stat(configPath); err == nil && info.IsDir() {
			if err := os.RemoveAll(configPath); err != nil {
				fmt.Printf("❌ Error removing directory: %v\n", err)
				errorCount++
				continue
			}
			fmt.Printf("✅ Removed directory: %s\n", configPath)
			processedCount++
			continue
		}

		// Create new configuration based on file type
		var configData interface{}
		if strings.Contains(configPath, "subscription.json") {
			configData = createSubscriptionConfig(trialStartDate, trialEndDate)
		} else if strings.Contains(configPath, "account.json") {
			configData = createAccountConfig(newDeviceID, newUserID, userEmail, trialStartDate)
		} else {
			configData = createStateConfig(newDeviceID, newUserID, userEmail, trialStartDate, trialEndDate)
		}

		// Save new configuration
		jsonData, err := json.MarshalIndent(configData, "", "  ")
		if err != nil {
			fmt.Printf("❌ Error marshaling JSON: %v\n", err)
			errorCount++
			continue
		}

		if err := os.WriteFile(configPath, jsonData, 0644); err != nil {
			fmt.Printf("❌ Error writing file: %v\n", err)
			errorCount++
			continue
		}

		fmt.Println("✅ New configuration saved successfully")
		processedCount++

		// Display account details for state.json files
		if strings.Contains(configPath, "state.json") {
			fmt.Println("\nAccount Details:")
			fmt.Printf("User ID: %s\n", newUserID)
			fmt.Printf("Device ID: %s\n", newDeviceID)
			fmt.Printf("Email: %s\n", userEmail)
			fmt.Println("\nTrial period: 14 days")
			fmt.Printf("Start date: %s\n", trialStartDate.Format("2006-01-02"))
			fmt.Printf("End date: %s\n", trialEndDate.Format("2006-01-02"))
		}
	}

	fmt.Printf("\n📊 Processing Summary:\n")
	fmt.Printf("Total paths: %d\n", len(configPaths))
	fmt.Printf("Successfully processed: %d\n", processedCount)
	fmt.Printf("Errors: %d\n", errorCount)

	fmt.Println("\n🎉 Augment extension trial reset complete!")
	fmt.Println("\n⚠️ Important:")
	fmt.Println("1. Please restart your editor (VS Code or Cursor) for changes to take effect")
	fmt.Println("2. Create a new account when prompted")
	fmt.Println("3. The trial period will be active for 14 days")
	fmt.Println("4. Consider using a different network connection or VPN if issues persist")

	return nil
}

// main function
func main() {
	fmt.Println("🚀 Augment Extension Trial Reset Tool")
	fmt.Println("====================================\n")

	if err := resetAugmentTrial(); err != nil {
		fmt.Printf("\n❌ An error occurred: %v\n", err)
		waitForKeypress()
		os.Exit(1)
	}

	waitForKeypress()
}
