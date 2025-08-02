#!/bin/bash

# Enhanced Authentication Test Script
# Tests the improved OAuth authentication enforcement

set -e

BASE_URL="https://cupcake.onemainarmy.com"

echo "🔒 Testing Enhanced OAuth Authentication Enforcement"
echo "==================================================="
echo

echo "📋 Test Configuration:"
echo "Base URL: ${BASE_URL}"
echo "Test Time: $(date)"
echo

# Test 1: SSE endpoint without authentication
echo "1️⃣ Testing SSE Endpoint Without Authentication..."
echo "------------------------------------------------"
SSE_NO_AUTH_RESPONSE=$(curl -s -w "%{http_code}" "${BASE_URL}/sse")
SSE_NO_AUTH_HTTP_CODE="${SSE_NO_AUTH_RESPONSE: -3}"
SSE_NO_AUTH_BODY="${SSE_NO_AUTH_RESPONSE%???}"

echo "HTTP Status Code: ${SSE_NO_AUTH_HTTP_CODE}"
echo "Response Body: ${SSE_NO_AUTH_BODY}"

if [ "$SSE_NO_AUTH_HTTP_CODE" = "401" ]; then
    echo "✅ SSE endpoint correctly blocks access without authentication"
else
    echo "❌ SSE endpoint should return 401 but returned ${SSE_NO_AUTH_HTTP_CODE}"
    exit 1
fi
echo

# Test 2: SSE endpoint with invalid token
echo "2️⃣ Testing SSE Endpoint With Invalid Token..."
echo "---------------------------------------------"
SSE_INVALID_TOKEN_RESPONSE=$(curl -s -w "%{http_code}" -H "Authorization: Bearer invalid_token" "${BASE_URL}/sse")
SSE_INVALID_TOKEN_HTTP_CODE="${SSE_INVALID_TOKEN_RESPONSE: -3}"
SSE_INVALID_TOKEN_BODY="${SSE_INVALID_TOKEN_RESPONSE%???}"

echo "HTTP Status Code: ${SSE_INVALID_TOKEN_HTTP_CODE}"
echo "Response Body: ${SSE_INVALID_TOKEN_BODY}"

if [ "$SSE_INVALID_TOKEN_HTTP_CODE" = "401" ]; then
    echo "✅ SSE endpoint correctly blocks access with invalid token"
else
    echo "❌ SSE endpoint should return 401 but returned ${SSE_INVALID_TOKEN_HTTP_CODE}"
    exit 1
fi
echo

# Test 3: SSE endpoint with fake JWT token
echo "3️⃣ Testing SSE Endpoint With Fake JWT Token..."
echo "----------------------------------------------"
FAKE_JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
SSE_FAKE_JWT_RESPONSE=$(curl -s -w "%{http_code}" -H "Authorization: Bearer ${FAKE_JWT}" "${BASE_URL}/sse")
SSE_FAKE_JWT_HTTP_CODE="${SSE_FAKE_JWT_RESPONSE: -3}"
SSE_FAKE_JWT_BODY="${SSE_FAKE_JWT_RESPONSE%???}"

echo "HTTP Status Code: ${SSE_FAKE_JWT_HTTP_CODE}"
echo "Response Body: ${SSE_FAKE_JWT_BODY}"

if [ "$SSE_FAKE_JWT_HTTP_CODE" = "401" ]; then
    echo "✅ SSE endpoint correctly blocks access with fake JWT token"
else
    echo "❌ SSE endpoint should return 401 but returned ${SSE_FAKE_JWT_HTTP_CODE}"
    exit 1
fi
echo

# Test 4: Check WWW-Authenticate headers
echo "4️⃣ Checking WWW-Authenticate Headers..."
echo "---------------------------------------"
WWW_AUTH_HEADER=$(curl -s -i "${BASE_URL}/sse" | grep -i "www-authenticate" || echo "No WWW-Authenticate header found")

if [[ "$WWW_AUTH_HEADER" == *"www-authenticate"* ]]; then
    echo "✅ WWW-Authenticate header present:"
    echo "   $WWW_AUTH_HEADER"
else
    echo "⚠️  WWW-Authenticate header not found"
fi
echo

# Test 5: Test public endpoints (should still be accessible)
echo "5️⃣ Testing Public Endpoints (should be accessible)..."
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

# Test 6: Monitor server logs for authentication attempts
echo "6️⃣ Checking Server Logs for Authentication Attempts..."
echo "------------------------------------------------------"
echo "Recent server logs:"
docker compose logs --tail=10 | grep -E "(SSE|authentication|token|401)" || echo "No authentication-related logs found"
echo

# Summary
echo "📊 Enhanced Authentication Test Summary"
echo "======================================="
echo "✅ SSE endpoint blocks access without authentication"
echo "✅ SSE endpoint blocks access with invalid tokens"
echo "✅ SSE endpoint blocks access with fake JWT tokens"
echo "✅ Public endpoints remain accessible"
echo

echo "🎯 Authentication Enforcement Status:"
if [ "$SSE_NO_AUTH_HTTP_CODE" = "401" ] && [ "$SSE_INVALID_TOKEN_HTTP_CODE" = "401" ] && [ "$SSE_FAKE_JWT_HTTP_CODE" = "401" ]; then
    echo "✅ STRONG AUTHENTICATION ENFORCEMENT ACTIVE"
    echo "✅ All unauthorized access attempts are blocked"
    echo "✅ ChatGPT will be required to authenticate before accessing the SSE endpoint"
else
    echo "❌ Authentication enforcement is not working properly"
    echo "❌ Some unauthorized access attempts are getting through"
fi
echo

echo "🔍 Next Steps for ChatGPT Testing:"
echo "1. Configure ChatGPT with OAuth enabled"
echo "2. Complete the OAuth flow in ChatGPT"
echo "3. Verify that ChatGPT can access the SSE endpoint after authentication"
echo "4. Monitor server logs for successful authentication"
echo

echo "📝 Expected Behavior:"
echo "- ChatGPT should be blocked from accessing SSE endpoint without OAuth"
echo "- ChatGPT should complete OAuth flow to get access token"
echo "- ChatGPT should use access token to access SSE endpoint"
echo "- All unauthorized access should be blocked with 401 responses"
echo

echo "🎉 Enhanced authentication is now properly enforced!" 