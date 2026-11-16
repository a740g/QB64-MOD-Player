# Makefile for QB64 MOD Player

# Detect OS and executable extension
ifeq ($(OS),Windows_NT)
    EXE = .exe
else
    EXE =
endif

# Search paths for QB64-PE compiler (supports QB64PE_PATH from environment / CI)
SEARCH_PATHS := $(QB64PE_PATH) . ../qb64pe ../QB64pe ../QB64PE

QB64PE_PATH_FOUND = $(firstword $(foreach dir,$(SEARCH_PATHS),$(if $(wildcard $(dir)/qb64pe$(EXE)),$(dir),)))

ifneq ($(QB64PE_PATH_FOUND),)
    QB64PE ?= $(QB64PE_PATH_FOUND)/qb64pe$(EXE)
else
    QB64PE ?= qb64pe$(EXE)
endif

# Compiler flags
CFLAGS = -x -w -e

# Project name
PROJECT = QB64MODPlayer

# Source files (only QB64MODPlayer.bas, others are .bi includes)
SOURCES = source/QB64MODPlayer.bas

# Include files (.bi and .bm files)
INCLUDES = $(wildcard source/*.bi) $(wildcard source/*.bm)

# Resource files
RESOURCES = source/QB64MODPlayer.ico

# Output executable in root
EXECUTABLE = $(PROJECT)$(EXE)

# Test suite files
TEST_SOURCES = tests/test_main.bas
TEST_EXECUTABLE = test_main$(EXE)

# Help message text
define HELP_TEXT
QB64 MOD Player Makefile
Usage:
  make          - Build the project
  make release  - Build the project with C++ optimizations
  make test     - Build and run the test suite (optional: ARGS="filter")
  make clean    - Remove build artifacts
  make help     - Show this help message

Requirements:
  - QB64-PE must be installed and in PATH
  - Set QB64PE variable if not in default PATH
endef

# Default target
all: $(EXECUTABLE)

# Release target with C++ optimizations
release: clean
	$(MAKE) all CFLAGS="$(CFLAGS) -f:OptimizeCppProgram=true"

# Compile main executable
$(EXECUTABLE): $(SOURCES) $(INCLUDES) $(RESOURCES)
	$(QB64PE) $(CFLAGS) $(SOURCES) -o $(EXECUTABLE)

# Compile and run test suite
test: $(TEST_EXECUTABLE)
	./$(TEST_EXECUTABLE) $(ARGS)

$(TEST_EXECUTABLE): $(TEST_SOURCES) $(INCLUDES)
	$(QB64PE) $(CFLAGS) $(TEST_SOURCES) -o $(TEST_EXECUTABLE)

# Clean build artifacts
clean:
ifeq ($(OS),Windows_NT)
	@if exist "$(EXECUTABLE)" del /q /f "$(EXECUTABLE)"
	@if exist "source\$(EXECUTABLE)" del /q /f "source\$(EXECUTABLE)"
	@if exist "$(TEST_EXECUTABLE)" del /q /f "$(TEST_EXECUTABLE)"
	@if exist "tests\$(TEST_EXECUTABLE)" del /q /f "tests\$(TEST_EXECUTABLE)"
else
	rm -f $(EXECUTABLE) source/$(EXECUTABLE) $(TEST_EXECUTABLE) tests/$(TEST_EXECUTABLE)
endif

# Help
help:
	$(info $(HELP_TEXT))
	@:

.PHONY: all release test clean help
