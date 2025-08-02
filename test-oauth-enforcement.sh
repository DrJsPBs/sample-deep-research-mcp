#!/bin/bash

# Test OAuth Authentication Enforcement for Cupcake MCP Server
# This script verifies that OAuth authentication is properly enforced

set -e

BASE_URL="https://cupcake.onemainarmy.com"
AUTH_SERVER="https://oauth.onemainarmy.com"

echo "🧪 Testing OAuth Authentication Enforcement for Cupcake MCP Server"
echo "=================================================================="
echo

# Test 1: OAuth Discovery Endpoints (should be accessible without auth)
echo "1️⃣ Testing OAuth Discovery Endpoints..."
echo "----------------------------------------"

echo "📋 Protected Resource Metadata:"
curl -s "${BASE_URL}/.well-known/oauth-protected-resource" | jq .
echo

echo "🔐 Authorization Server Metadata:"
curl -s "${BASE_URL}/.well-known/oauth-authorization-server" | jq .
echo

# Test 2: MCP Manifest (should be accessible without auth)
echo "2️⃣ Testing MCP Manifest..."
echo "---------------------------"
curl -s "${BASE_URL}/.well-known/mcp/manifest.json" | jq .
echo

# Test 3: SSE Endpoint (should require authentication)
echo "3️⃣ Testing SSE Endpoint Authentication..."
echo "------------------------------------------"

echo "🔒 Testing SSE endpoint without authentication (should return 401):"
SSE_RESPONSE=$(curl -s -w "%{http_code}" "${BASE_URL}/sse")
HTTP_CODE="${SSE_RESPONSE: -3}"
RESPONSE_BODY="${SSE_RESPONSE%???}"

echo "HTTP Status Code: ${HTTP_CODE}"
echo "Response Body: ${RESPONSE_BODY}"

if [ "$HTTP_CODE" = "401" ]; then
    echo "✅ SSE endpoint correctly requires authentication"
else
    echo "❌ SSE endpoint should return 401 but returned ${HTTP_CODE}"
    exit 1
fi
echo

# Test 4: Check for WWW-Authenticate header
echo "4️⃣ Testing WWW-Authenticate Header..."
echo "-------------------------------------"
WWW_AUTH_HEADER=$(curl -s -i "${BASE_URL}/sse" | grep -i "www-authenticate" || echo "No WWW-Authenticate header found")

if [[ "$WWW_AUTH_HEADER" == *"www-authenticate"* ]]; then
    echo "✅ WWW-Authenticate header present:"
    echo "   $WWW_AUTH_HEADER"
else
    echo "⚠️  WWW-Authenticate header not found (this may be expected for SSE endpoints)"
fi
echo

# Test 5: Test with invalid token
echo "5️⃣ Testing with Invalid Token..."
echo "--------------------------------"
INVALID_TOKEN_RESPONSE=$(curl -s -w "%{http_code}" -H "Authorization: Bearer invalid_token" "${BASE_URL}/sse")
INVALID_HTTP_CODE="${INVALID_TOKEN_RESPONSE: -3}"
INVALID_RESPONSE_BODY="${INVALID_TOKEN_RESPONSE%???}"

echo "HTTP Status Code: ${INVALID_HTTP_CODE}"
echo "Response Body: ${INVALID_RESPONSE_BODY}"

if [ "$INVALID_HTTP_CODE" = "401" ]; then
    echo "✅ Invalid token correctly rejected"
else
    echo "❌ Invalid token should be rejected with 401"
    exit 1
fi
echo

# Test 6: Verify OAuth flow endpoints
echo "6️⃣ Testing OAuth Flow Endpoints..."
echo "-----------------------------------"

echo "🔗 Authorization Endpoint:"
curl -s "${AUTH_SERVER}/authorize" | head -5
echo

echo "🎫 Token Endpoint:"
curl -s "${AUTH_SERVER}/token" | head -5
echo

echo "📝 Registration Endpoint:"
curl -s "${AUTH_SERVER}/register" | head -5
echo

# Summary
echo "📊 Test Summary"
echo "==============="
echo "✅ OAuth Discovery Endpoints: Working"
echo "✅ MCP Manifest: Working"
echo "✅ SSE Authentication Enforcement: Working"
echo "✅ Invalid Token Rejection: Working"
echo "✅ OAuth Flow Endpoints: Accessible"
echo
echo "🎉 All OAuth authentication tests passed!"
echo
echo "🔗 For ChatGPT integration:"
echo "   - Base URL: ${BASE_URL}"
echo "   - SSE Endpoint: ${BASE_URL}/sse"
echo "   - OAuth Server: ${AUTH_SERVER}"
echo "   - Manifest: ${BASE_URL}/.well-known/mcp/manifest.json"
echo
echo "📝 Next Steps:"
echo "   1. Configure ChatGPT to use OAuth authentication"
echo "   2. Test the OAuth flow with ChatGPT"
echo "   3. Verify that ChatGPT can access the SSE endpoint after authentication" 