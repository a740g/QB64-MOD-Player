# Makefile for QB64 MOD Player

# Detect OS and executable extension
ifeq ($(OS),Windows_NT)
    EXE = .exe
else
    EXE =
endif

# QB64-PE compiler (relative path or in PATH)
ifeq ($(wildcard ../QB64pe/qb64pe$(EXE)),)
    QB64PE ?= qb64pe$(EXE)
else
    QB64PE ?= ../QB64pe/qb64pe$(EXE)
endif

# Compiler flags
CFLAGS = -x -w -e

# Project name
PROJECT = QB64MODPlayer

# Source files (only QB64MODPlayer.bas, others are .bi includes)
SOURCES = source/QB64MODPlayer.bas

# Include files (.bi files)
INCLUDES = $(wildcard source/*.bi)

# Resource files
RESOURCES = source/QB64MODPlayer.ico

# Output executable in root
EXECUTABLE = $(PROJECT)$(EXE)

# Default target
all: $(EXECUTABLE)

# Release target with C++ optimizations
release: CFLAGS += -f:OptimizeCppProgram=true
release: $(EXECUTABLE)

# Compile
$(EXECUTABLE): $(SOURCES) $(INCLUDES) $(RESOURCES)
	$(QB64PE) $(CFLAGS) $(SOURCES) -o $(EXECUTABLE)

# Clean build artifacts
clean:
ifeq ($(OS),Windows_NT)
	@if exist "$(EXECUTABLE)" del /q /f "$(EXECUTABLE)"
else
	rm -f $(EXECUTABLE)
endif

# Help
help:
	@echo "QB64 MOD Player Makefile"
	@echo "Usage:"
	@echo "  make          - Build the project"
	@echo "  make release  - Build the project with C++ optimizations"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "Requirements:"
	@echo "  - QB64-PE must be installed and in PATH"
	@echo "  - Set QB64PE variable if not in default PATH"

.PHONY: all release clean help
