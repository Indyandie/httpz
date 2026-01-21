# AGENTS.md

This file provides guidelines for agentic coding assistants working in the `httpz` repository.
`httpz` is a lightweight HTTP server implemented entirely in ZSH, using the `zsh/net/tcp` module.
It supports static HTML serving, file serving (with directory listing), and various MIME types.

## Project Structure

```
.
├── httpz.zsh              # Main HTTP server script (executable)
├── test_httpz.zsh         # Test script using curl for header/content-type validation
├── README.md              # Usage, TODO, references
├── test/                  # Test assets and fixtures
│   ├── data.json
│   ├── config.yml
│   ├── query.html
│   ├── style.css
│   ├── script.js
│   ├── rfc-9110-cover.jpeg/png
│   ├── minion.gif
│   ├── icon.svg
│   └── subdir/
├── test02/                # Additional test files
│   ├── index.html
│   ├── list.html
│   └── script.js
├── css/                   # Example CSS (pico.min.css)
├── js/                    # Example JS (rapidoc-min.js)
├── json/                  # Example JSON (pet-oas.json)
├── yaml/                  # Example YAML (poke-oas.yaml/yml)
├── image/                 # Example images (webp, gif, jpeg, png)
├── openapi/               # OpenAPI HTML examples
├── hello.html             # Simple HTML
├── index.html             # Root index
└── style.css              # Root CSS
```

## Commands

### Prerequisites

- ZSH with `zsh/net/tcp` and `zsh/stat` modules
- `curl` for testing (NixOS paths in test script: `/run/current-system/sw/bin/curl`)
- `shellcheck` for linting

### Syntax Check

```bash
zsh -n httpz.zsh
```

Verifies syntax without execution.

### Test

**Full test suite:**

```bash
# Start server in background (use -p 8080 to match test default)
./httpz.zsh -f -p 8080 &
SERVER_PID=$!
./test_httpz.zsh http://localhost 8080
kill $SERVER_PID
```

Runs header/content-type tests for HTML, JSON, YAML, CSS, JS, PNG, JPEG, GIF, WebP, SVG.

**Single test (manual curl example):**

```bash
# Test JSON content-type
curl -s -D - -I http://localhost:1234/test/data.json | grep -i content-type
# Expected: content-type: application/json
```

**Test server manually:**

```bash
# Static HTML server
./httpz.zsh -h -p 1234 -v

# File server with directory listing
./httpz.zsh -f -p 1234 -v
```

Visit `http://localhost:1234/` in browser/curl.

### Build

No build step required. Scripts are self-contained.

### Run Development Server

```bash
./httpz.zsh -f -p 1234 -v  # Verbose file server
```

- `-s/--static`: Simple static response
- `-h/--html`: HTML routing
- `-f/--file`: File/directory serving
- `-p/--port PORT`: Port (default 1234)
- `-v/--verbose`: Diagnostics

## Code Style Guidelines

### Language & Modules

- **ZSH only**. Use `#!/usr/bin/env zsh`
- Load modules explicitly:
  ```zsh
  zmodload zsh/net/tcp
  zmodload -F zsh/stat b:zstat
  ```

### Command-Line Parsing

- Use `zparseopts -D -E -F -` for flags/options.
- Example:
  ```zsh
  zparseopts -D -E -F - \
      s=serv_type -static=serv_type \
      h=serv_type -html=serv_type \
      p:=port_value -port:=port_value \
      v=verbose_flag
  ```
- Validate and set defaults (e.g., `PORT=1234`).

### Variables

- **Constants**: `typeset -r VAR=value`
- **Associative arrays**: `typeset -A conf=( [KEY] value )`
  - Keys uppercase (e.g., `PORT HOST CHUNK_SIZE`)
- **Locals**: `local var="$1"`
- **Read-only configs**: `typeset -r conf=(...)`

### Functions

- **Documentation**: Use block comment header with `#######################################`
  ```zsh
  #######################################
  # Function name
  # Description
  # Arguments: $1, $2
  # Outputs: ...
  #######################################
  func() { ... }
  ```
- **Snake_case naming**: e.g., `http_response_neue`, `directory_listing`, `serve_file_or_404`
- **Pure functions**: Avoid side effects; return via `print` or stdout.
- **Error handling**: `print "Error: message."; exit 1`

### Formatting

- **Indentation**: 4 spaces (no tabs).
- **Line length**: < 100 chars preferred.
- **Quotes**: Double quotes for vars `"$var"`, single for literals `'EOF'`.
- **Newlines**: `BR="\r\n"` for HTTP.
- **Case statements**: Use `case ... in ... ;; esac`
- **Globbing**: `setopt EXTENDED_GLOB` when needed.

### HTTP Handling Conventions

- **Responses**: Use `http_response_neue status msg [body_path] [custom_header] [body]`
- **MIME types** (from `CONTENT_TYPES` assoc):
  | Ext      | Type                   |
  | -------- | ---------------------- |
  | html     | text/html              |
  | css      | text/css               |
  | png      | image/png              |
  | gif      | image/gif              |
  | jpeg/jpg | image/jpeg             |
  | webp     | image/webp             |
  | js       | application/javascript |
  | yml/yaml | application/yaml       |
  | json     | application/json       |
- **Routing**: Separate handlers e.g., `html-handler`, `file-handler`
- **Headers**: Parse with `read -r -u $fd`, store in assoc `req_headers`
- **Body**: Handle `Content-Length`; read with `read -u $fd -k $len`

### Error Handling

- Validate inputs: `[[ -z $var ]] && { print "Error"; exit 1; }`
- Port validation: `[[ ! $PORT =~ ^[0-9]+$ ]] && exit 1`
- File existence: `[[ -f "$path" ]] || 404 response`
- Use `501 Not Implemented` for unsupported methods.

### Testing Guidelines

- Add tests to `test/` dir.
- Update `test_httpz.zsh` for new MIME types/endpoints.
- Test edge cases: missing files, invalid ports, large files.
- Verify with `curl -v` and browser.

### Git Conventions

- Commit messages: `feat: add SVG support`, `fix: directory listing quoting`
- No force pushes.
- Branch: `feat/new-feature`

### TODO Integration

- Check README.md TODO list before changes.
- Mark items as `[x]` when completed.

## For Agents

- **Before edits**: `shellcheck httpz.zsh`
- **After edits**: Run full tests.
- **Verify changes**: `diff` before/after, manual curl.
- **Mimic style**: Copy function patterns from `httpz.zsh`.
- **No new deps**: Pure ZSH.
- **Security**: Sanitize paths, no `eval`.

(147 lines)
