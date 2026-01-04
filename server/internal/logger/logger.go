package logger

import (
	"bufio"
	"io"
	"os"
	"path/filepath"
	"sync"

	"github.com/sirupsen/logrus"
	"gopkg.in/natefinch/lumberjack.v2"
)

// Log is the global logger instance
var Log *logrus.Logger

// logFile holds the current log file writer for reading logs
var logFile *lumberjack.Logger
var logFilePath string
var logMutex sync.RWMutex

func init() {
	Log = logrus.New()
	Log.SetOutput(os.Stdout)
	Log.SetFormatter(&logrus.TextFormatter{
		FullTimestamp:   true,
		TimestampFormat: "2006-01-02 15:04:05",
	})
	Log.SetLevel(logrus.DebugLevel) // Default to debug
}

// LogConfig holds logging configuration
type LogConfig struct {
	Level      string
	JSON       bool
	File       string
	MaxSizeMB  int
	MaxBackups int
	MaxAgeDays int
}

// Configure sets up the logger with full configuration
func Configure(cfg LogConfig) error {
	SetLevel(cfg.Level)
	SetJSON(cfg.JSON)

	if cfg.File != "" {
		if err := SetLogFile(cfg.File, cfg.MaxSizeMB, cfg.MaxBackups, cfg.MaxAgeDays); err != nil {
			return err
		}
	}

	return nil
}

// SetLogFile configures file-based logging with rotation
func SetLogFile(path string, maxSizeMB, maxBackups, maxAgeDays int) error {
	// Ensure log directory exists
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	logMutex.Lock()
	defer logMutex.Unlock()

	// Create rotating file writer
	logFile = &lumberjack.Logger{
		Filename:   path,
		MaxSize:    maxSizeMB,  // MB
		MaxBackups: maxBackups, // number of old files
		MaxAge:     maxAgeDays, // days
		Compress:   true,       // compress old files
	}
	logFilePath = path

	// Write to both stdout and file
	multiWriter := io.MultiWriter(os.Stdout, logFile)
	Log.SetOutput(multiWriter)

	Log.WithFields(logrus.Fields{
		"path":        path,
		"max_size_mb": maxSizeMB,
		"max_backups": maxBackups,
		"max_age":     maxAgeDays,
	}).Info("Log file configured")

	return nil
}

// GetLogFilePath returns the current log file path
func GetLogFilePath() string {
	logMutex.RLock()
	defer logMutex.RUnlock()
	return logFilePath
}

// ReadLogFile reads the last N lines from the log file
func ReadLogFile(lines int) ([]string, error) {
	logMutex.RLock()
	path := logFilePath
	logMutex.RUnlock()

	if path == "" {
		return nil, nil
	}

	file, err := os.Open(path)
	if err != nil {
		if os.IsNotExist(err) {
			return []string{}, nil
		}
		return nil, err
	}
	defer file.Close()

	// Read all lines into a buffer
	var allLines []string
	scanner := bufio.NewScanner(file)
	// Increase buffer size for long lines
	buf := make([]byte, 0, 64*1024)
	scanner.Buffer(buf, 1024*1024)

	for scanner.Scan() {
		allLines = append(allLines, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	// Return last N lines
	if len(allLines) <= lines {
		return allLines, nil
	}
	return allLines[len(allLines)-lines:], nil
}

// ClearLogFile truncates the current log file
func ClearLogFile() error {
	logMutex.Lock()
	defer logMutex.Unlock()

	if logFilePath == "" {
		return nil
	}

	// Rotate the log file (this effectively clears it)
	if logFile != nil {
		return logFile.Rotate()
	}
	return nil
}

// SetLevel sets the logging level
func SetLevel(level string) {
	switch level {
	case "debug":
		Log.SetLevel(logrus.DebugLevel)
	case "info":
		Log.SetLevel(logrus.InfoLevel)
	case "warn":
		Log.SetLevel(logrus.WarnLevel)
	case "error":
		Log.SetLevel(logrus.ErrorLevel)
	default:
		Log.SetLevel(logrus.DebugLevel)
	}
}

// SetJSON enables JSON formatted logging
func SetJSON(enabled bool) {
	if enabled {
		Log.SetFormatter(&logrus.JSONFormatter{
			TimestampFormat: "2006-01-02T15:04:05Z07:00",
		})
	} else {
		Log.SetFormatter(&logrus.TextFormatter{
			FullTimestamp:   true,
			TimestampFormat: "2006-01-02 15:04:05",
		})
	}
}

// Convenience functions for common logging patterns

// Debug logs a debug message
func Debug(msg string) {
	Log.Debug(msg)
}

// Debugf logs a formatted debug message
func Debugf(format string, args ...interface{}) {
	Log.Debugf(format, args...)
}

// Info logs an info message
func Info(msg string) {
	Log.Info(msg)
}

// Infof logs a formatted info message
func Infof(format string, args ...interface{}) {
	Log.Infof(format, args...)
}

// Warn logs a warning message
func Warn(msg string) {
	Log.Warn(msg)
}

// Warnf logs a formatted warning message
func Warnf(format string, args ...interface{}) {
	Log.Warnf(format, args...)
}

// Error logs an error message
func Error(msg string) {
	Log.Error(msg)
}

// Errorf logs a formatted error message
func Errorf(format string, args ...interface{}) {
	Log.Errorf(format, args...)
}

// WithField returns a log entry with a field
func WithField(key string, value interface{}) *logrus.Entry {
	return Log.WithField(key, value)
}

// WithFields returns a log entry with fields
func WithFields(fields logrus.Fields) *logrus.Entry {
	return Log.WithFields(fields)
}

// WithError returns a log entry with an error
func WithError(err error) *logrus.Entry {
	return Log.WithError(err)
}
