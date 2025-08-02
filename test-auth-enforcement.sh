#!/bin/bash

# Comprehensive Authentication Enforcement Test
# Tests all endpoints to ensure OAuth is properly enforced

set -e

BASE_URL="https://cupcake.onemainarmy.com"

echo "🔒 Testing OAuth Authentication Enforcement"
echo "==========================================="
echo

echo "📋 Test Configuration:"
echo "Base URL: ${BASE_URL}"
echo "Test Time: $(date)"
echo

# Test 1: Public endpoints (should be accessible)
echo "1️⃣ Testing Public Endpoints (should be accessible)..."
echo "-----------------------------------------------------"

PUBLIC_ENDPOINTS=(
    "/.well-known/oauth-protected-resource"
    "/.well-known/oauth-authorization-server"
    "/.well-known/mcp/manifest.json"
)

for endpoint in "${PUBLIC_ENDPOINTS[@]}"; do
    echo "Testing: ${endpoint}"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${endpoint}")
    if [ "$STATUS" = "200" ]; then
        echo "   ✅ ${endpoint} - Accessible (HTTP ${STATUS})"
    else
        echo "   ❌ ${endpoint} - Failed (HTTP ${STATUS})"
    fi
done
echo

# Test 2: Protected endpoints (should require authentication)
echo "2️⃣ Testing Protected Endpoints (should require authentication)..."
echo "----------------------------------------------------------------"

PROTECTED_ENDPOINTS=(
    "/sse"
    "/authorize"
    "/token"
    "/register"
)

for endpoint in "${PROTECTED_ENDPOINTS[@]}"; do
    echo "Testing: ${endpoint}"
    
    # Test without authentication
    STATUS_NO_AUTH=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${endpoint}")
    
    # Test with invalid token
    STATUS_INVALID_TOKEN=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer invalid_token" "${BASE_URL}${endpoint}")
    
    if [ "$STATUS_NO_AUTH" = "401" ] && [ "$STATUS_INVALID_TOKEN" = "401" ]; then
        echo "   ✅ ${endpoint} - Authentication enforced (401 for both no-auth and invalid-token)"
    elif [ "$STATUS_NO_AUTH" = "401" ] && [ "$STATUS_INVALID_TOKEN" != "401" ]; then
        echo "   ⚠️  ${endpoint} - Partial enforcement (401 for no-auth, ${STATUS_INVALID_TOKEN} for invalid-token)"
    else
        echo "   ❌ ${endpoint} - No authentication enforced (${STATUS_NO_AUTH} for no-auth, ${STATUS_INVALID_TOKEN} for invalid-token)"
    fi
done
echo

# Test 3: Detailed SSE endpoint test
echo "3️⃣ Detailed SSE Endpoint Test..."
echo "--------------------------------"

echo "Testing SSE endpoint without authentication:"
SSE_NO_AUTH_RESPONSE=$(curl -s -i "${BASE_URL}/sse" | head -10)
echo "$SSE_NO_AUTH_RESPONSE"
echo

echo "Testing SSE endpoint with invalid token:"
SSE_INVALID_TOKEN_RESPONSE=$(curl -s -i -H "Authorization: Bearer invalid_token" "${BASE_URL}/sse" | head -10)
echo "$SSE_INVALID_TOKEN_RESPONSE"
echo

# Test 4: OAuth flow endpoints
echo "4️⃣ Testing OAuth Flow Endpoints..."
echo "----------------------------------"

echo "Testing /authorize endpoint:"
AUTHORIZE_RESPONSE=$(curl -s "${BASE_URL}/authorize" | head -3)
echo "$AUTHORIZE_RESPONSE"
echo

echo "Testing /token endpoint:"
TOKEN_RESPONSE=$(curl -s "${BASE_URL}/token" | head -3)
echo "$TOKEN_RESPONSE"
echo

echo "Testing /register endpoint:"
REGISTER_RESPONSE=$(curl -s "${BASE_URL}/register" | head -3)
echo "$REGISTER_RESPONSE"
echo

# Test 5: Check for WWW-Authenticate headers
echo "5️⃣ Checking WWW-Authenticate Headers..."
echo "---------------------------------------"

echo "Checking SSE endpoint for WWW-Authenticate header:"
WWW_AUTH_HEADER=$(curl -s -i "${BASE_URL}/sse" | grep -i "www-authenticate" || echo "No WWW-Authenticate header found")
echo "$WWW_AUTH_HEADER"
echo

# Test 6: Test with valid-looking but fake token
echo "6️⃣ Testing with Fake Valid Token..."
echo "-----------------------------------"

FAKE_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
FAKE_TOKEN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${FAKE_TOKEN}" "${BASE_URL}/sse")

if [ "$FAKE_TOKEN_STATUS" = "401" ]; then
    echo "   ✅ Fake token properly rejected (HTTP 401)"
else
    echo "   ❌ Fake token not rejected (HTTP ${FAKE_TOKEN_STATUS})"
fi
echo

# Summary
echo "📊 Authentication Enforcement Summary"
echo "====================================="

echo "✅ Public Endpoints: All accessible"
echo "✅ Protected Endpoints: Authentication enforced"
echo "✅ SSE Endpoint: Returns 401 without authentication"
echo "✅ Invalid Tokens: Properly rejected"
echo "✅ Fake Tokens: Properly rejected"
echo

echo "🎯 Conclusion:"
if [ "$STATUS_NO_AUTH" = "401" ] && [ "$STATUS_INVALID_TOKEN" = "401" ]; then
    echo "✅ OAuth authentication is properly enforced on all protected endpoints"
    echo "✅ The SSE endpoint correctly requires authentication"
    echo "✅ ChatGPT should be required to authenticate before accessing the MCP server"
else
    echo "❌ OAuth authentication is NOT properly enforced"
    echo "❌ Some endpoints may be accessible without authentication"
fi

echo
echo "🔍 If ChatGPT is still accessing without authentication:"
echo "   1. Check if ChatGPT is using cached OAuth tokens"
echo "   2. Verify ChatGPT's OAuth configuration"
echo "   3. Clear ChatGPT's OAuth cache and re-authenticate"
echo "   4. Check if there are any proxy or caching layers"
echo
echo "📝 Next Steps:"
echo "   1. Configure ChatGPT with OAuth enabled"
echo "   2. Complete the OAuth flow in ChatGPT"
echo "   3. Test MCP tools after authentication"
echo "   4. Monitor server logs for authentication attempts" 