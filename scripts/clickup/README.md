# ClickUp API Integration Scripts

Comprehensive bash scripts for interacting with the ClickUp API, providing task management, automation, and file handling capabilities.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Scripts Overview](#scripts-overview)
- [Usage](#usage)
  - [Task Management](#task-management)
  - [Comments](#comments)
  - [Attachments](#attachments)
  - [Organization](#organization)
  - [File Downloads](#file-downloads)
- [Command Reference](#command-reference)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Contributing](#contributing)

## Features

- **Comprehensive Task Management**: Create, update, search, and batch manage tasks
- **Comment System**: Add comments and retrieve full conversation threads with replies
- **Attachment Handling**: Download individual attachments or batch download all images
- **Secure Configuration**: Environment-based API key management
- **Error Handling**: Robust error detection with informative messages
- **Retry Logic**: Automatic retry mechanisms for downloads and API calls
- **Progress Indication**: Visual feedback for long-running operations
- **Color-Coded Output**: Enhanced readability with color-coded messages
- **Batch Operations**: Bulk update capabilities for efficient task management

## Prerequisites

- **Bash 4.0+**: Modern bash shell (check with `bash --version`)
- **curl**: HTTP client for API requests
- **jq**: JSON processor for parsing API responses
- **ClickUp API Key**: Personal API token from ClickUp

### Install Dependencies

```bash
# macOS
brew install jq curl

# Ubuntu/Debian
sudo apt-get install jq curl

# CentOS/RHEL
sudo yum install jq curl
```

## Installation

1. **Ensure scripts are in the correct location**:
   ```bash
   cd ~/dotfiles/scripts/clickup
   ```

2. **Make scripts executable**:
   ```bash
   chmod +x clickup-api.sh clickup-download.sh
   ```

3. **Set up configuration**:
   ```bash
   cp .env.example .env
   ```

4. **Edit `.env` with your API key**:
   ```bash
   # Get your API key from: https://app.clickup.com/settings/apps
   echo "CLICKUP_API_KEY=pk_YOUR_API_KEY_HERE" > .env
   ```

5. **Source the environment file** (optional, for current session):
   ```bash
   source .env
   export CLICKUP_API_KEY
   ```

6. **Add to shell profile** (optional, for persistence):
   ```bash
   echo 'export PATH="$HOME/dotfiles/scripts/clickup:$PATH"' >> ~/.zshrc
   echo 'export CLICKUP_API_KEY="pk_YOUR_API_KEY_HERE"' >> ~/.zshrc.private
   ```

## Configuration

### Environment Variables

Create a `.env` file in the scripts directory or export these variables:

```bash
# Required
CLICKUP_API_KEY=pk_YOUR_PERSONAL_API_TOKEN

# Optional
CLICKUP_ATTACHMENTS_DIR=./clickup_attachments  # Download directory
CLICKUP_TEAM_ID=123456                        # Default team for searches
CLICKUP_DEFAULT_LIST_ID=789012                # Default list for tasks
CLICKUP_DOWNLOAD_TIMEOUT=30                   # Download timeout in seconds
CLICKUP_DOWNLOAD_RETRIES=3                    # Retry attempts for downloads
```

### Finding IDs

```bash
# Get your team ID
curl -H "Authorization: pk_YOUR_API_KEY" https://api.clickup.com/api/v2/team

# Get workspace lists
curl -H "Authorization: pk_YOUR_API_KEY" https://api.clickup.com/api/v2/folder/FOLDER_ID/list

# Get list details
./clickup-api.sh get-list LIST_ID
```

## Scripts Overview

### clickup-api.sh

Main API wrapper providing comprehensive ClickUp functionality:
- Task CRUD operations (Create, Read, Update, Delete)
- Comment management with thread support
- Attachment handling and batch downloads
- Status updates and field modifications
- Search and filtering capabilities
- Batch operations for efficiency

### clickup-download.sh

Enhanced file downloader with enterprise features:
- Retry logic with exponential backoff
- Resume support for partial downloads
- Progress indicators
- Timeout configuration
- Verbose debugging mode
- Automatic directory creation

## Usage

### Task Management

#### Create Tasks

```bash
# Basic task creation
./clickup-api.sh create-task LIST_ID "Task Name" "Description"

# With priority and tags
./clickup-api.sh create-task LIST_ID "Bug Fix" "Fix login issue" 2 "bug,urgent"

# With custom fields
./clickup-api.sh create-task-with-fields LIST_ID "Feature" "New feature" FIELD_ID "value" 1 "enhancement"
```

Priority levels:
- 1 = Urgent (🔴)
- 2 = High (🟠)
- 3 = Normal (🟡) - default
- 4 = Low (🔵)

#### Update Tasks

```bash
# Update name and description
./clickup-api.sh update-task TASK_ID "New Name" "New Description"

# Update multiple fields at once
./clickup-api.sh update-task-fields TASK_ID \
  name="Updated Task" \
  status="in progress" \
  priority=1 \
  due_date="2024-12-31"

# Update status only
./clickup-api.sh update-status TASK_ID "complete"

# Batch update status for multiple tasks
./clickup-api.sh batch-update-status "done" TASK_ID1 TASK_ID2 TASK_ID3
```

#### Retrieve Tasks

```bash
# Get task with subtasks and comments
./clickup-api.sh get-task TASK_ID

# List all tasks in a list
./clickup-api.sh fetch-tasks LIST_ID

# Include archived tasks
./clickup-api.sh fetch-tasks LIST_ID true true

# Search tasks by name
./clickup-api.sh search-tasks TEAM_ID "login bug"
```

### Comments

```bash
# Get all comments including replies
./clickup-api.sh get-comments TASK_ID

# Add a comment
./clickup-api.sh add-comment TASK_ID "Investigation started"

# Add detailed comment
./clickup-api.sh add-comment TASK_ID "Found root cause:
- Database connection timeout
- Need to increase connection pool size"
```

### Attachments

```bash
# List all attachments
./clickup-api.sh get-attachments TASK_ID

# Download specific attachment
./clickup-api.sh download-attachment TASK_ID ATTACHMENT_ID

# Auto-download all images
./clickup-api.sh auto-download-images TASK_ID

# Downloads saved to: ./clickup_attachments/
```

### Organization

```bash
# Get list details
./clickup-api.sh get-list LIST_ID

# Get subtasks
./clickup-api.sh get-subtasks TASK_ID
```

### File Downloads

```bash
# Basic download
./clickup-download.sh https://example.com/file.pdf report.pdf

# With retry and timeout options
./clickup-download.sh -r 5 -t 60 https://example.com/large.zip archive.zip

# Resume partial download
./clickup-download.sh --continue https://example.com/video.mp4 video.mp4

# Quiet mode (no progress bar)
./clickup-download.sh -q https://example.com/data.json data.json

# Verbose debugging
./clickup-download.sh -v https://example.com/file.txt debug.txt
```

## Command Reference

### clickup-api.sh Commands

| Command | Description | Example |
|---------|-------------|---------|
| `get-task` | Get task details with subtasks and comments | `./clickup-api.sh get-task abc123` |
| `create-task` | Create new task | `./clickup-api.sh create-task LIST_ID "Name" "Desc" [priority] [tags] [status]` |
| `update-task` | Update task name and description | `./clickup-api.sh update-task TASK_ID "New Name" ["New Desc"]` |
| `update-task-fields` | Update multiple fields | `./clickup-api.sh update-task-fields TASK_ID field=value ...` |
| `update-status` | Update task status | `./clickup-api.sh update-status TASK_ID "in progress"` |
| `batch-update-status` | Update multiple tasks' status | `./clickup-api.sh batch-update-status "done" ID1 ID2 ...` |
| `get-comments` | Get all comments with replies | `./clickup-api.sh get-comments TASK_ID` |
| `add-comment` | Add comment to task | `./clickup-api.sh add-comment TASK_ID "text"` |
| `get-attachments` | List task attachments | `./clickup-api.sh get-attachments TASK_ID` |
| `download-attachment` | Download specific attachment | `./clickup-api.sh download-attachment TASK_ID ATTACH_ID` |
| `auto-download-images` | Download all image attachments | `./clickup-api.sh auto-download-images TASK_ID` |
| `get-subtasks` | Get task's subtasks | `./clickup-api.sh get-subtasks TASK_ID` |
| `get-list` | Get list details | `./clickup-api.sh get-list LIST_ID` |
| `fetch-tasks` | Get all tasks from list | `./clickup-api.sh fetch-tasks LIST_ID [archived] [subtasks]` |
| `search-tasks` | Search tasks by name | `./clickup-api.sh search-tasks TEAM_ID "query"` |
| `create-task-with-fields` | Create task with custom fields | `./clickup-api.sh create-task-with-fields LIST_ID "Name" "Desc" FIELD_ID VALUE` |

### clickup-download.sh Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-r NUM` | `--retries NUM` | Maximum retry attempts (default: 3) |
| `-t SEC` | `--timeout SEC` | Timeout in seconds (default: 30) |
| `-v` | `--verbose` | Enable verbose output for debugging |
| `-q` | `--quiet` | Suppress progress bar |
| `-c` | `--continue` | Resume partial downloads |
| `-h` | `--help` | Show help message |

## Examples

### Example 1: Complete Task Workflow

```bash
# Create a high-priority bug task
TASK_ID=$(./clickup-api.sh create-task 900100123456 \
  "Critical: Login fails for SSO users" \
  "Users reporting 500 errors when using SSO login" \
  1 "bug,critical,sso" | jq -r '.id')

echo "Created task: $TASK_ID"

# Add initial investigation comment
./clickup-api.sh add-comment $TASK_ID "Starting investigation. Checking logs..."

# Update status to in progress
./clickup-api.sh update-status $TASK_ID "in progress"

# After investigation, add findings
./clickup-api.sh add-comment $TASK_ID "Root cause identified:
- SAML certificate expired
- Affects all SSO providers
- Fix: Update certificate in config"

# Download relevant screenshots
./clickup-api.sh auto-download-images $TASK_ID

# Update with resolution
./clickup-api.sh update-task-fields $TASK_ID \
  name="[RESOLVED] SSO Login Issue" \
  status="complete" \
  description="Fixed by updating SAML certificates"
```

### Example 2: Bulk Task Management

```bash
# Get all open tasks
./clickup-api.sh fetch-tasks 900100123456 | \
  jq -r '.tasks[] | select(.status.status == "open") | .id' > open_tasks.txt

# Batch update old tasks
OLD_TASK_IDS=$(cat open_tasks.txt | head -5)
./clickup-api.sh batch-update-status "backlog" $OLD_TASK_IDS

# Search and update specific tasks
./clickup-api.sh search-tasks TEAM_ID "documentation" | \
  jq -r '.tasks[].id' | \
  xargs -I {} ./clickup-api.sh update-task-fields {} priority=4
```

### Example 3: Attachment Processing

```bash
# Download all attachments from a task
TASK_ID="86czv3zkx"

# Get attachment list
./clickup-api.sh get-attachments $TASK_ID | jq '.[] | {id, title, size}'

# Download all images
./clickup-api.sh auto-download-images $TASK_ID

# Process downloaded images
for img in ./clickup_attachments/*.png; do
    echo "Processing: $img"
    # Add your image processing here
done
```

### Example 4: Comment Thread Management

```bash
# Get full comment thread
./clickup-api.sh get-comments TASK_ID | \
  jq '.comments[] | {user: .user.username, text: .comment_text, date: .date}'

# Add formatted update
./clickup-api.sh add-comment TASK_ID "$(cat <<EOF
## Status Update

### Completed
- Database migration
- API endpoint updates

### In Progress
- Frontend integration
- Testing

### Blockers
- Waiting for design approval
EOF
)"
```

## Best Practices

### API Key Management

1. **Never commit API keys**:
   ```bash
   echo "CLICKUP_API_KEY=*" >> .gitignore
   echo ".env" >> .gitignore
   ```

2. **Use environment variables**:
   ```bash
   # In ~/.zshrc.private or ~/.bashrc.private
   export CLICKUP_API_KEY="pk_YOUR_KEY"
   ```

3. **Rotate keys regularly**: Generate new keys quarterly

### Performance Optimization

1. **Use batch operations** when possible:
   ```bash
   # Good: Single batch update
   ./clickup-api.sh batch-update-status "done" ID1 ID2 ID3

   # Avoid: Multiple individual updates
   for id in ID1 ID2 ID3; do
     ./clickup-api.sh update-status $id "done"
   done
   ```

2. **Cache frequently used data**:
   ```bash
   # Cache list details
   ./clickup-api.sh get-list LIST_ID > list_cache.json
   ```

3. **Use specific field requests** when possible

### Error Handling

1. **Check command success**:
   ```bash
   if ./clickup-api.sh create-task LIST_ID "Task" "Desc"; then
     echo "Task created successfully"
   else
     echo "Failed to create task"
     exit 1
   fi
   ```

2. **Parse JSON responses safely**:
   ```bash
   # Check for valid JSON
   response=$(./clickup-api.sh get-task TASK_ID)
   if echo "$response" | jq empty 2>/dev/null; then
     task_name=$(echo "$response" | jq -r '.name')
   else
     echo "Invalid response"
   fi
   ```

## Troubleshooting

### Common Issues

#### Command not found: jq
```bash
# Install jq
brew install jq  # macOS
sudo apt-get install jq  # Ubuntu
```

#### API Authentication Failed
```bash
# Verify API key
echo $CLICKUP_API_KEY

# Test API key
curl -H "Authorization: $CLICKUP_API_KEY" \
  https://api.clickup.com/api/v2/user
```

#### Permission Denied
```bash
# Make scripts executable
chmod +x clickup-api.sh clickup-download.sh
```

#### Downloads Failing
```bash
# Check attachments directory
mkdir -p ./clickup_attachments

# Verify write permissions
touch ./clickup_attachments/test.txt

# Use verbose mode for debugging
./clickup-download.sh -v URL FILENAME
```

#### Rate Limiting
ClickUp API has rate limits. If you encounter 429 errors:
- Add delays between requests: `sleep 1`
- Implement exponential backoff
- Use batch operations where available

### Debug Mode

Enable verbose output for troubleshooting:
```bash
# For API calls
set -x  # Enable bash debug mode
./clickup-api.sh get-task TASK_ID

# For downloads
./clickup-download.sh -v URL FILENAME
```

## Security

### Recommendations

1. **Secure Storage**: Store API keys in password managers or secure vaults
2. **Minimal Permissions**: Use API keys with minimum required permissions
3. **Access Control**: Restrict script access on shared systems
4. **Audit Logs**: Monitor API usage for unusual activity
5. **HTTPS Only**: All API calls use HTTPS by default

### Security Checklist

- [ ] API key stored in environment variable, not hardcoded
- [ ] `.env` file added to `.gitignore`
- [ ] Regular key rotation schedule established
- [ ] Scripts have appropriate file permissions (755 or more restrictive)
- [ ] Sensitive data not logged in verbose mode
- [ ] Downloads validated before processing

## Contributing

### Adding New Features

1. **Follow existing patterns** in the codebase
2. **Add error handling** for new commands
3. **Update documentation** with examples
4. **Test thoroughly** before committing

### Code Style

- Use meaningful variable names
- Add comments for complex logic
- Follow bash best practices
- Use color codes consistently
- Implement proper error messages

### Testing

Test new features with:
```bash
# Syntax check
bash -n clickup-api.sh

# Shellcheck for best practices
shellcheck clickup-api.sh

# Test with sample data
./clickup-api.sh get-task TEST_TASK_ID
```

## Advanced Usage

### Integration with Other Tools

```bash
# Pipe to other commands
./clickup-api.sh fetch-tasks LIST_ID | jq '.tasks[] | .name'

# Export to CSV
./clickup-api.sh fetch-tasks LIST_ID | \
  jq -r '.tasks[] | [.id, .name, .status.status] | @csv' > tasks.csv

# Create task from git commit
git log -1 --pretty=format:"%s" | \
  xargs -I {} ./clickup-api.sh create-task LIST_ID "{}" "From commit"
```

### Automation Examples

```bash
#!/bin/bash
# Daily task report

TASKS=$(./clickup-api.sh fetch-tasks LIST_ID)

echo "Daily Task Report - $(date)"
echo "========================"
echo "Total: $(echo $TASKS | jq '.tasks | length')"
echo "Open: $(echo $TASKS | jq '[.tasks[] | select(.status.status == "open")] | length')"
echo "In Progress: $(echo $TASKS | jq '[.tasks[] | select(.status.status == "in progress")] | length')"
echo "Complete: $(echo $TASKS | jq '[.tasks[] | select(.status.status == "complete")] | length')"
```

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review ClickUp API documentation: https://clickup.com/api
3. Verify script permissions and dependencies
4. Test with verbose mode enabled

## License

These scripts are provided as-is for use with the ClickUp API. Ensure compliance with ClickUp's API terms of service.