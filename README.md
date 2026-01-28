# Ralph Loop - Interactive PRD Completion Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)

Ralph Loop is a production-ready tool that iteratively calls Claude to complete complex Product Requirements Documents (PRDs) by working through tasks one at a time until all acceptance criteria pass. It provides zero-edit usage with comprehensive help, progress tracking, and smart resume capabilities.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Command-Line Flags](#command-line-flags)
- [PRD File Format](#prd-file-format)
- [Example PRD Files](#example-prd-files)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Iterative Task Completion**: Automatically works through PRD tasks in priority order
- **Smart Resume**: Continue from where you left off after interruption
- **Progress Tracking**: Detailed logging with timestamps and status updates
- **PRD Analysis**: Get quality feedback on your PRD before running
- **Real-Time Visualization**: Live progress indicators showing task status
- **Markdown or JSON**: Write PRDs in markdown and auto-convert to JSON
- **Error Handling**: Comprehensive error messages with actionable solutions
- **Verbose/Debug Modes**: Detailed logging for troubleshooting

## Prerequisites

Before installing Ralph Loop, ensure you have the following dependencies:

### Required Dependencies

1. **Bash 4.0 or higher**
   ```bash
   # Check your bash version
   bash --version
   ```

2. **Claude CLI**
   - Install from: [https://docs.anthropic.com/claude/docs/claude-cli](https://docs.anthropic.com/claude/docs/claude-cli)
   - Verify installation:
   ```bash
   which claude
   ```

3. **jq** (JSON processor)
   - Version 1.6 or higher required
   - Used for JSON parsing and manipulation

4. **Standard Unix utilities**
   - `cat`, `grep`, `sed`, `date`, `mktemp`
   - Usually pre-installed on macOS and Linux

## Installation

### macOS Installation

1. **Install Homebrew** (if not already installed)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install jq**
   ```bash
   brew install jq
   ```

3. **Install Claude CLI**
   ```bash
   # Follow official installation instructions at:
   # https://docs.anthropic.com/claude/docs/claude-cli
   ```

4. **Download Ralph Loop**
   ```bash
   # Clone or download the repository
   git clone https://github.com/paullovvik/ralph-loop.git
   cd ralph-loop
   ```

5. **Make the script executable**
   ```bash
   chmod +x ralph-loop
   ```

6. **Add to PATH (optional)**
   ```bash
   # Add to your ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/ralph-loop"

   # Or create a symbolic link
   sudo ln -s /path/to/ralph-loop/ralph-loop /usr/local/bin/ralph-loop
   ```

### Linux Installation

1. **Install jq**
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install jq

   # Fedora/RHEL
   sudo dnf install jq

   # Arch Linux
   sudo pacman -S jq
   ```

2. **Install Claude CLI**
   ```bash
   # Follow official installation instructions at:
   # https://docs.anthropic.com/claude/docs/claude-cli
   ```

3. **Download Ralph Loop**
   ```bash
   git clone https://github.com/paullovvik/ralph-loop.git
   cd ralph-loop
   ```

4. **Make the script executable**
   ```bash
   chmod +x ralph-loop
   ```

5. **Add to PATH (optional)**
   ```bash
   # Add to your ~/.bashrc
   echo 'export PATH="$PATH:'"$(pwd)"'"' >> ~/.bashrc
   source ~/.bashrc

   # Or create a symbolic link
   sudo ln -s $(pwd)/ralph-loop /usr/local/bin/ralph-loop
   ```

### Verify Installation

After installation, verify everything works:

```bash
# Check Ralph Loop is accessible
ralph-loop --help

# Verify all dependencies
which claude    # Should show path to claude CLI
which jq        # Should show path to jq
bash --version  # Should show 4.0 or higher
```

## Quick Start

1. **Create a PRD file** (see [examples/simple-feature.md](examples/simple-feature.md))
   ```markdown
   # My Feature PRD

   ## Task: Implement user authentication
   **Category**: Backend
   **Priority**: 1

   ### Acceptance Criteria
   - API endpoint /auth/login accepts email and password
   - Returns JWT token on successful authentication
   - Test: curl -X POST /auth/login returns 200 with token
   ```

2. **Run Ralph Loop**
   ```bash
   ralph-loop my-feature.md
   ```

3. **Review results**
   - `my-feature.json` - Final task status with completion data
   - `progress.txt` - Detailed log of all iterations and learnings

## Usage

### Basic Usage

```bash
ralph-loop <prd-file> [OPTIONS]
```

### Common Scenarios

**Run with defaults (15 iterations max)**
```bash
ralph-loop my-project.md
```

**Analyze PRD quality before running**
```bash
ralph-loop my-project.md --analyze-prd
```

**Run with custom iteration limit**
```bash
ralph-loop complex-project.md --max-iterations 30
```

**Resume interrupted run**
```bash
ralph-loop my-project.md --resume
```

**Debug mode for troubleshooting**
```bash
ralph-loop my-project.md --debug
```

**Verbose mode with progress details**
```bash
ralph-loop my-project.md --verbose --max-iterations 25
```

## Command-Line Flags

| Flag | Description | Default |
|------|-------------|---------|
| `<prd-file>` | Path to PRD file (.md or .json) | **Required** |
| `--max-iterations N` | Maximum iterations to run | 15 |
| `--verbose` | Show detailed progress and API metadata | Off |
| `--debug` | Show full Claude output and internal state | Off |
| `--resume` | Resume from last checkpoint | Off |
| `--analyze-prd` | Analyze PRD quality and exit | Off |
| `--help` | Show comprehensive help message | - |

## PRD File Format

Ralph Loop accepts PRD files in either Markdown or JSON format.

### Markdown Format

```markdown
# Project Title

Brief project overview (optional)

## Task: Task Title
**Category**: Category Name
**Priority**: 1

Task description goes here.

### Acceptance Criteria
- First acceptance criterion
- Second criterion with test: ./test-script.sh passes
- Third criterion

## Task: Second Task Title
**Category**: Another Category
**Priority**: 2

### Acceptance Criteria
- Criterion one
- Criterion two
```

### JSON Format

```json
{
  "title": "Project Title",
  "overview": "Brief project overview",
  "projectDirectory": "/path/to/project",
  "tasks": [
    {
      "id": "task-1",
      "title": "Task Title",
      "category": "Category Name",
      "priority": 1,
      "description": "Task description",
      "acceptanceCriteria": [
        "First criterion",
        "Second criterion"
      ],
      "passes": false,
      "completedAt": null,
      "attempts": 0
    }
  ]
}
```

### Required Fields

**Markdown:**
- Each task must have: title, Category, Priority, Acceptance Criteria section
- Priorities must be unique integers

**JSON:**
- Top-level: `title`, `tasks` (array)
- Each task: `id`, `title`, `category`, `priority`, `acceptanceCriteria`, `passes`

## Example PRD Files

Ralph Loop includes several example PRD files in the `examples/` directory:

### [simple-feature.md](examples/simple-feature.md)
A basic example with 2-3 well-written tasks. Perfect for first-time users to understand the format.

```bash
ralph-loop examples/simple-feature.md
```

### [complex-project.json](examples/complex-project.json)
A realistic project with 5-7 tasks showing more complex scenarios and dependencies.

```bash
ralph-loop examples/complex-project.json --max-iterations 25
```

### [good-prd-example.md](examples/good-prd-example.md)
Demonstrates best practices:
- Specific, testable acceptance criteria
- Clear test commands
- Proper priority ordering
- Comprehensive task descriptions

```bash
ralph-loop examples/good-prd-example.md --analyze-prd
```

### [bad-prd-example.md](examples/bad-prd-example.md)
Shows common mistakes (use with `--analyze-prd` to see suggestions):
- Vague acceptance criteria
- Missing test commands
- Unclear priorities
- Ambiguous goals

```bash
ralph-loop examples/bad-prd-example.md --analyze-prd
```

## Testing

Ralph Loop includes a comprehensive test suite to verify functionality.

### Running All Tests

Run the complete test suite:

```bash
./tests/test-all.sh
```

This runs all test suites including:
- Markdown to JSON conversion tests
- PRD validation tests
- Resume functionality tests
- Help and documentation tests
- PRD analysis tests

### Running Specific Tests

Run individual test suites:

```bash
# Test markdown to JSON conversion
./tests/test-conversion.sh

# Test PRD validation
./tests/test-validation.sh

# Test resume functionality
./tests/test-resume.sh

# Test help system
./tests/test-help.sh

# Test PRD analysis
./tests/test-analysis.sh
```

### Running JavaScript/Jest Tests

For the JavaScript unit tests (models, database):

```bash
npm test
```

### Test Requirements

- All test scripts are executable (chmod +x is applied automatically)
- Tests create temporary files in a test directory that is cleaned up automatically
- Tests do not require API keys or external services
- Progress visualization tests may be skipped in non-interactive environments

## Troubleshooting

### Common Issues and Solutions

#### "PRD file not found"
```
Error: Could not find PRD file: my-project.md

Solution: Check the file path is correct
  - Use absolute path: /full/path/to/my-project.md
  - Or relative path from current directory: ./my-project.md

Run: ralph-loop --help for more information
```

**Fix:** Verify the file exists and path is correct:
```bash
ls -la my-project.md
ralph-loop $(pwd)/my-project.md
```

#### "Permission denied"
```
Error: Cannot read PRD file (permission denied)

Solution: Fix file permissions
  chmod +r my-project.md
```

**Fix:** Make the file readable:
```bash
chmod +r my-project.md
# Or make ralph-loop executable:
chmod +x ralph-loop
```

#### "Max iterations reached"
```
⚠️  Max iterations (15) reached with incomplete tasks

Remaining tasks:
  - Task 3: Implement API endpoint (0% complete)
  - Task 4: Add test coverage (0% complete)

To continue: ralph-loop my-project.md --resume --max-iterations 30
```

**Fix:** Resume with higher iteration limit:
```bash
ralph-loop my-project.md --resume --max-iterations 30
```

#### "Validation failed: Duplicate priority values"
```
❌ Validation Error: Tasks 2 and 3 both have priority 2

Solution: Each task must have a unique priority value
  - Edit your PRD to assign unique priorities (1, 2, 3, etc.)
  - Run: ralph-loop my-project.md --analyze-prd for more suggestions
```

**Fix:** Edit your PRD file and ensure each task has a unique priority number.

#### "Claude CLI not found"
```
Error: claude command not found

Solution: Install Claude CLI from:
  https://docs.anthropic.com/claude/docs/claude-cli
```

**Fix:** Install Claude CLI following the official documentation.

#### "jq command not found"
```
Error: jq is required but not installed

Solution:
  macOS: brew install jq
  Linux: sudo apt-get install jq  (Ubuntu/Debian)
         sudo dnf install jq      (Fedora/RHEL)
```

**Fix:** Install jq using your package manager (see [Installation](#installation)).

#### Conversion Failures

If markdown to JSON conversion fails:

1. **Check markdown format**
   - Each task must start with `## Task:`
   - Must include `**Category**:` and `**Priority**:` lines
   - Must have `### Acceptance Criteria` section

2. **Validate with analysis**
   ```bash
   ralph-loop my-project.md --analyze-prd
   ```

3. **Review examples**
   ```bash
   cat examples/good-prd-example.md
   ```

### Getting More Help

- **View comprehensive help**: `ralph-loop --help`
- **Enable verbose mode**: `ralph-loop my-project.md --verbose`
- **Enable debug mode**: `ralph-loop my-project.md --debug`
- **Analyze PRD quality**: `ralph-loop my-project.md --analyze-prd`

## Files Created by Ralph Loop

When you run Ralph Loop, it creates the following files:

| File | Description |
|------|-------------|
| `<prd-name>.json` | JSON version of your PRD with task status tracking |
| `progress.txt` | Detailed log of all iterations, actions, and learnings |
| `progress-<timestamp>.txt` | Archived progress file (when starting fresh) |

These files are created in the same directory as your input PRD file.

## Contributing

Contributions are welcome! Here's how to contribute:

### Reporting Issues

1. Check existing issues to avoid duplicates
2. Include the following in your report:
   - Ralph Loop version (first line of `ralph-loop --help`)
   - OS and Bash version
   - Complete error message
   - Steps to reproduce
   - Your PRD file (if relevant)

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test thoroughly:
   ```bash
   ./tests/test-all.sh
   ```
5. Commit with clear messages:
   ```bash
   git commit -m "Add feature: description"
   ```
6. Push to your fork: `git push origin feature/my-feature`
7. Open a Pull Request

### Development Guidelines

- Follow existing code style and conventions
- Add tests for new features in `tests/` directory
- Update documentation for user-facing changes
- Keep commits focused and atomic
- Write clear commit messages

### Testing

Run the test suite before submitting:

```bash
# Run all tests
./tests/test-all.sh

# Run specific test
./tests/test-conversion.sh
./tests/test-validation.sh
./tests/test-resume.sh
```

### Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Assume good intentions

## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

## Additional Resources

- **Claude CLI Documentation**: https://docs.anthropic.com/claude/docs/claude-cli
- **jq Documentation**: https://stedolan.github.io/jq/
- **Bash Reference**: https://www.gnu.org/software/bash/manual/

## Tips for Success

1. **Start small**: Test with simple PRDs (2-3 tasks) before complex projects
2. **Use analysis**: Run `--analyze-prd` to get feedback before starting
3. **Review examples**: Study `examples/good-prd-example.md` for best practices
4. **Be specific**: Write clear, testable acceptance criteria
5. **Include tests**: Add actual test commands in your criteria
6. **Monitor progress**: Check `progress.txt` to understand Claude's actions
7. **Use resume**: Don't restart from scratch if interrupted
8. **Iterate limits**: Start with default (15), increase if needed

## Support

If you encounter issues not covered in this README:

1. Check `ralph-loop --help` for detailed usage information
2. Review the [Troubleshooting](#troubleshooting) section
3. Look at example PRD files in `examples/`
4. Enable `--debug` mode to see detailed execution logs
5. Open an issue on GitHub with details

---

**Made with ❤️ using Claude**
