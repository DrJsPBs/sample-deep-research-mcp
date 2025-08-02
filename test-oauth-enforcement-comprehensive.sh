#!/bin/bash

# Comprehensive OAuth Enforcement Test Script
# Tests for ChatGPT OAuth bypass vulnerabilities

set -e

BASE_URL="https://cupcake.onemainarmy.com"
LOG_FILE="oauth_test_$(date +%Y%m%d_%H%M%S).log"

echo "🔒 Comprehensive OAuth Enforcement Test" | tee -a "$LOG_FILE"
echo "=====================================" | tee -a "$LOG_FILE"
echo "Base URL: $BASE_URL" | tee -a "$LOG_FILE"
echo "Test Time: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

test_endpoint() {
    local endpoint="$1"
    local expected_status="$2"
    local description="$3"
    local headers="$4"
    
    echo -e "${BLUE}Testing: $description${NC}" | tee -a "$LOG_FILE"
    echo "Endpoint: $endpoint" | tee -a "$LOG_FILE"
    
    if [ -n "$headers" ]; then
        response=$(curl -s -w "%{http_code}" -H "$headers" "$BASE_URL$endpoint" 2>/dev/null)
    else
        response=$(curl -s -w "%{http_code}" "$BASE_URL$endpoint" 2>/dev/null)
    fi
    
    status_code="${response: -3}"
    content="${response%???}"
    
    echo "Status: $status_code" | tee -a "$LOG_FILE"
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS: Expected $expected_status, got $status_code${NC}" | tee -a "$LOG_FILE"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL: Expected $expected_status, got $status_code${NC}" | tee -a "$LOG_FILE"
        echo "Response: $content" | tee -a "$LOG_FILE"
        ((TESTS_FAILED++))
    fi
    echo "" | tee -a "$LOG_FILE"
}

echo "1️⃣ Testing Public Discovery Endpoints" | tee -a "$LOG_FILE"
echo "=====================================" | tee -a "$LOG_FILE"

test_endpoint "/.well-known/oauth-protected-resource" "200" "OAuth Protected Resource Discovery"
test_endpoint "/.well-known/oauth-authorization-server" "200" "OAuth Authorization Server Discovery"
test_endpoint "/.well-known/mcp/manifest.json" "200" "MCP Manifest Discovery"

echo "2️⃣ Testing OAuth Flow Endpoints" | tee -a "$LOG_FILE"
echo "=================================" | tee -a "$LOG_FILE"

# These should return OAuth protocol responses, not 401
test_endpoint "/authorize" "400" "OAuth Authorization Endpoint (missing params)"
test_endpoint "/token" "405" "OAuth Token Endpoint (wrong method)"
test_endpoint "/register" "405" "OAuth Registration Endpoint (wrong method)"

echo "3️⃣ Testing Protected Endpoints Without Authentication" | tee -a "$LOG_FILE"
echo "=====================================================" | tee -a "$LOG_FILE"

test_endpoint "/sse" "401" "SSE Endpoint (no auth)"
test_endpoint "/sse" "401" "SSE Endpoint (invalid token)" "Authorization: Bearer invalid_token"
test_endpoint "/sse" "401" "SSE Endpoint (fake token)" "Authorization: Bearer fake_token_12345"

echo "4️⃣ Testing MCP Tools Without Authentication" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"

# Test tool endpoints directly (these should be protected)
test_endpoint "/tools/search" "404" "Search Tool Endpoint (no auth)"
test_endpoint "/tools/fetch" "404" "Fetch Tool Endpoint (no auth)"

echo "5️⃣ Testing OAuth Callback" | tee -a "$LOG_FILE"
echo "==========================" | tee -a "$LOG_FILE"

test_endpoint "/oauth/callback" "400" "OAuth Callback (missing params)"
test_endpoint "/oauth/callback?code=test&state=test" "400" "OAuth Callback (invalid params)"

echo "6️⃣ Testing Invalid Endpoints" | tee -a "$LOG_FILE"
echo "=============================" | tee -a "$LOG_FILE"

test_endpoint "/invalid-endpoint" "404" "Invalid Endpoint"
test_endpoint "/api/v1/search" "404" "Fake API Endpoint"
test_endpoint "/tools" "404" "Tools Base Endpoint"

echo "7️⃣ Testing Headers and Security" | tee -a "$LOG_FILE"
echo "=================================" | tee -a "$LOG_FILE"

# Test various header combinations
test_endpoint "/sse" "401" "SSE with empty Authorization" "Authorization: "
test_endpoint "/sse" "401" "SSE with malformed Authorization" "Authorization: Bearer"
test_endpoint "/sse" "401" "SSE with wrong token type" "Authorization: Basic dGVzdDp0ZXN0"

echo "8️⃣ Testing ChatGPT-Specific Bypass Attempts" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"

# Test potential ChatGPT bypass patterns
test_endpoint "/sse?token=bypass" "401" "SSE with query param token"
test_endpoint "/sse?access_token=bypass" "401" "SSE with query param access_token"
test_endpoint "/sse" "401" "SSE with X-Access-Token header" "X-Access-Token: bypass_token"
test_endpoint "/sse" "401" "SSE with X-API-Key header" "X-API-Key: fake_api_key"

echo "9️⃣ Testing OAuth Token Validation" | tee -a "$LOG_FILE"
echo "==================================" | tee -a "$LOG_FILE"

# Test various token formats
test_endpoint "/sse" "401" "SSE with short token" "Authorization: Bearer short"
test_endpoint "/sse" "401" "SSE with long fake token" "Authorization: Bearer $(printf 'A%.0s' {1..100})"
test_endpoint "/sse" "401" "SSE with special chars in token" "Authorization: Bearer token!@#$%^&*()"

echo "🔍 Summary" | tee -a "$LOG_FILE"
echo "=========" | tee -a "$LOG_FILE"
echo "Tests Passed: $TESTS_PASSED" | tee -a "$LOG_FILE"
echo "Tests Failed: $TESTS_FAILED" | tee -a "$LOG_FILE"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))" | tee -a "$LOG_FILE"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! OAuth enforcement is working correctly.${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "✅ OAuth authentication is properly enforced" | tee -a "$LOG_FILE"
    echo "✅ No bypass vulnerabilities detected" | tee -a "$LOG_FILE"
    echo "✅ ChatGPT cannot access protected endpoints without authentication" | tee -a "$LOG_FILE"
else
    echo -e "${RED}⚠️  Some tests failed! OAuth enforcement may have issues.${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "❌ OAuth authentication may not be properly enforced" | tee -a "$LOG_FILE"
    echo "❌ Potential bypass vulnerabilities detected" | tee -a "$LOG_FILE"
    echo "❌ ChatGPT may be able to access protected endpoints without authentication" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "📋 Recommendations:" | tee -a "$LOG_FILE"
echo "1. If tests failed, review the authentication middleware" | tee -a "$LOG_FILE"
echo "2. Ensure FastMCP OAuth provider is properly configured" | tee -a "$LOG_FILE"
echo "3. Check server logs for authentication attempts" | tee -a "$LOG_FILE"
echo "4. Test with actual ChatGPT OAuth flow" | tee -a "$LOG_FILE"
echo "5. Monitor for unauthorized access attempts" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "📄 Log saved to: $LOG_FILE" | tee -a "$LOG_FILE" 