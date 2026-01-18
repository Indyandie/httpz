#!/usr/bin/env zsh

# test_headers.zsh - Test httpz server header handling with curl

# Usage: ./test_headers.zsh [server_url] [port]
# Default: http://localhost 8080

# Command paths
curl_cmd="/run/current-system/sw/bin/curl"
cut_cmd="/run/current-system/sw/bin/cut"
cat_cmd="/run/current-system/sw/bin/cat"
rm_cmd="/run/current-system/sw/bin/rm"
grep_cmd="/run/current-system/sw/bin/grep"
sed_cmd="/run/current-system/sw/bin/sed"
tr_cmd="/run/current-system/sw/bin/tr"
head_cmd="/run/current-system/sw/bin/head"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'  # No Color

SERVER_URL=${1:-http://localhost}
PORT=${2:-8080}
BASE_URL="$SERVER_URL:$PORT"

# Results array: test_name|status|passed
results=()
total_tests=0
passed_tests=0

echo "${BOLD}Testing httpz server headers at $BASE_URL${NC}"
echo "${BOLD}==========================================${NC}"

# Function to send request and check response
test_header() {
    local desc="$1"
    local curl_args="$2"
    local path="$3"
    local expected_content_type="$4"
    local expected_status="${5:-200}"

    local url="$BASE_URL$path"

    echo "\n${YELLOW}$desc${NC}"
    echo "${BLUE}Request headers:${NC}"
    if [[ "$desc" == "Custom User-Agent" ]]; then
        echo "  User-Agent: TestAgent/1.0"
    elif [[ "$desc" == "Custom Host header" ]]; then
        echo "  Host: example.com"
    elif [[ "$desc" == "Multiple headers" ]]; then
        echo "  X-Custom: value"
        echo "  X-Test: true"
        echo "  Accept: application/json"
    else
        echo "  (default headers)"
    fi
    echo "${CYAN}Command: curl -s -D /tmp/h -o /tmp/b -w 'HTTPSTATUS:%{http_code}' $curl_args '$url'${NC}"
    
    local tmp_h="/tmp/httpz_test_h_$$"
    local tmp_b="/tmp/httpz_test_b_$$"
    local response=$($curl_cmd -s -D $tmp_h -o $tmp_b -w 'HTTPSTATUS:%{http_code}' $curl_args "$url")
    local http_code=$(echo "$response" | $cut_cmd -d: -f2)
    local body=$($cat_cmd $tmp_b)
    local resp_headers=$($cat_cmd $tmp_h)
    $rm_cmd $tmp_h $tmp_b

    if [[ "$http_code" == "$expected_status" ]]; then
        echo "${GREEN}✓ Status: $http_code (expected $expected_status)${NC}"
    else
        echo "${RED}✗ Status: $http_code (expected $expected_status)${NC}"
    fi

    local content_type=$(echo "$resp_headers" | $grep_cmd -i '^content-type:' | $cut_cmd -d: -f2 | $sed_cmd 's/^ *//' | $sed_cmd 's/ *$//' | $tr_cmd -d '\r' | $tr_cmd '[:upper:]' '[:lower:]')
    echo "${BLUE}Expected content-type: $expected_content_type${NC}"
    if [[ "$content_type" == "$expected_content_type" ]]; then
        echo "${GREEN}✓ Content-Type matches${NC}"
    else
        echo "${RED}✗ Content-Type: $content_type (expected $expected_content_type)${NC}"
    fi

    echo "${BLUE}Response headers:${NC}"
    echo "$resp_headers"
    if [[ "$content_type" == image/* ]]; then
        echo "${BLUE}Response body preview:${NC} (binary image data, skipped)"
    else
        echo "${BLUE}Response body preview:${NC} $(echo "$body" | $head_cmd -c 100)..."
    fi

    # Determine file type
    local type
    if [[ "$path" == *.html ]]; then
        type="html"
    elif [[ "$path" == *.json ]]; then
        type="json"
    elif [[ "$path" == *.yaml ]] || [[ "$path" == *.yml ]]; then
        type="yaml"
    elif [[ "$path" == *.css ]]; then
        type="css"
    elif [[ "$path" == *.js ]]; then
        type="js"
    elif [[ "$path" == *.png ]]; then
        type="png"
    elif [[ "$path" == *.jpeg ]] || [[ "$path" == *.jpg ]]; then
        type="jpeg"
    elif [[ "$path" == *.gif ]]; then
        type="gif"
    elif [[ "$path" == *.webp ]]; then
        type="webp"
    elif [[ "$path" == *.svg ]]; then
        type="svg"
    else
        type="unknown"
    fi

    # Collect result
    local passed="✗"
    if [[ "$http_code" == "$expected_status" && "$content_type" == "$expected_content_type" ]]; then
        passed="✓"
        ((passed_tests++))
    fi
    ((total_tests++))
    results+=("$desc|$type|$http_code|$passed")
}

# Test cases
test_header "Basic request" "" "/test/query.html" "text/html"

test_header "Custom User-Agent" "-A 'TestAgent/1.0'" "/test/query.html" "text/html"

test_header "Custom Host header" "-H 'Host: example.com'" "/test/query.html" "text/html"

test_header "Multiple headers" "-H 'X-Custom: value' -H 'Accept: application/json'" "/test/query.html" "text/html"

test_header "Verbose mode" "" "/test/query.html" "text/html"

# Content-type tests
test_header "JSON file" "" "/test/data.json" "application/json"

test_header "YAML file" "" "/test/config.yaml" "application/yaml"

test_header "CSS file" "" "/test/style.css" "text/css"

test_header "JavaScript file" "" "/test/script.js" "application/javascript"

test_header "PNG image" "" "/test/rfc-9110-cover.png" "image/png"

test_header "JPEG image" "" "/test/rfc-9110-cover.jpeg" "image/jpeg"

test_header "GIF image" "" "/test/minion.gif" "image/gif"

test_header "WebP image" "" "/test/cat.webp" "image/webp"

test_header "SVG file" "" "/test/icon.svg" "text/plain"

echo "\n${GREEN}Header testing complete.${NC}"
echo "Check server verbose output for JSON header dumps."

# Print summary table
echo "\n${BOLD}Test Summary${NC}"
echo "| Test Name                  | File Type | Status | Passed |"
echo "|----------------------------|-----------|--------|--------|"
for result in "${results[@]}"; do
    local name=$(echo "$result" | $cut_cmd -d'|' -f1)
    local type=$(echo "$result" | $cut_cmd -d'|' -f2)
    local http_code=$(echo "$result" | $cut_cmd -d'|' -f3)
    local passed=$(echo "$result" | $cut_cmd -d'|' -f4)
    printf "| %-26s | %-9s | %-6s | %-6s |\n" "$name" "$type" "$http_code" "$passed"
done
echo "|----------------------------|-----------|--------|--------|"
printf "| %-26s | %-9s | %-6s | %-6s |\n" "Total: $passed_tests/$total_tests" "-" "-" "" " "
