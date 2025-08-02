#!/bin/bash

# Quick Fix Script for ChatGPT OAuth Errors
# Based on common OAuth issues from OpenAI community

echo "🔧 ChatGPT OAuth Error Quick Fix"
echo "================================"
echo

echo "📋 Current OAuth Configuration:"
echo "Base URL: https://cupcake.onemainarmy.com"
echo "SSE Endpoint: https://cupcake.onemainarmy.com/sse"
echo "OAuth Server: https://cupcake.onemainarmy.com"
echo "Manifest: https://cupcake.onemainarmy.com/.well-known/mcp/manifest.json"
echo

echo "🧪 Testing OAuth Endpoints..."
echo "-----------------------------"

# Test OAuth discovery
echo "1. Testing OAuth discovery endpoints..."
DISCOVERY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://cupcake.onemainarmy.com/.well-known/oauth-authorization-server)
if [ "$DISCOVERY_STATUS" = "200" ]; then
    echo "   ✅ OAuth discovery working"
else
    echo "   ❌ OAuth discovery failed (HTTP $DISCOVERY_STATUS)"
fi

# Test MCP manifest
echo "2. Testing MCP manifest..."
MANIFEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://cupcake.onemainarmy.com/.well-known/mcp/manifest.json)
if [ "$MANIFEST_STATUS" = "200" ]; then
    echo "   ✅ MCP manifest working"
else
    echo "   ❌ MCP manifest failed (HTTP $MANIFEST_STATUS)"
fi

# Test SSE authentication
echo "3. Testing SSE authentication..."
SSE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://cupcake.onemainarmy.com/sse)
if [ "$SSE_STATUS" = "401" ]; then
    echo "   ✅ SSE authentication properly enforced"
else
    echo "   ❌ SSE authentication not working (HTTP $SSE_STATUS)"
fi

echo
echo "🛠️  ChatGPT OAuth Fix Steps:"
echo "============================"
echo

echo "1️⃣ Clear ChatGPT OAuth Cache:"
echo "   • Go to ChatGPT Settings → Privacy → Connected Accounts"
echo "   • Remove any existing OAuth connections"
echo "   • Clear browser cache and cookies for ChatGPT"
echo

echo "2️⃣ Disable Browser Extensions:"
echo "   • Temporarily disable all browser extensions"
echo "   • Test OAuth flow in incognito/private mode"
echo

echo "3️⃣ Re-configure OAuth:"
echo "   • Add OAuth connection with these settings:"
echo "   • Base URL: https://cupcake.onemainarmy.com"
echo "   • SSE Endpoint: https://cupcake.onemainarmy.com/sse"
echo

echo "4️⃣ Test OAuth Flow:"
echo "   • Complete the OAuth authorization process"
echo "   • Verify that MCP tools work after authentication"
echo

echo "🚨 Common OAuth Error Solutions:"
echo "================================"
echo

echo "❌ 'Missing access token' Error:"
echo "   • Our implementation uses long-lived tokens (24 hours)"
echo "   • No refresh tokens to avoid ChatGPT refresh issues"
echo

echo "❌ 'OAuthCallback' Error:"
echo "   • Clear browser cache and cookies"
echo "   • Try incognito mode"
echo "   • Disable browser extensions"
echo

echo "❌ 'Unable to load conversation' Error:"
echo "   • Remove and re-add OAuth connection"
echo "   • Clear ChatGPT cache"
echo

echo "📞 If Issues Persist:"
echo "====================="
echo "• Check OpenAI community forums for latest OAuth issues"
echo "• Monitor server logs for OAuth-related errors"
echo "• Try different browser or device"
echo

echo "✅ Expected Behavior After Fix:"
echo "==============================="
echo "• Smooth OAuth authorization flow"
echo "• No OAuth error messages in ChatGPT"
echo "• MCP tools (search, fetch) work after authentication"
echo "• Authentication persists across sessions"
echo

echo "🎉 OAuth Configuration Summary:"
echo "==============================="
echo "✅ Self-hosted OAuth server (no external dependencies)"
echo "✅ Long-lived tokens (24 hours)"
echo "✅ No refresh token issues"
echo "✅ Simplified OAuth flow for ChatGPT compatibility"
echo "✅ Proper authentication enforcement"
echo

echo "🔗 Quick Test Commands:"
echo "======================="
echo "curl -s https://cupcake.onemainarmy.com/.well-known/oauth-authorization-server | jq ."
echo "curl -s https://cupcake.onemainarmy.com/.well-known/mcp/manifest.json | jq ."
echo "curl -s -i https://cupcake.onemainarmy.com/sse | head -5"
echo

echo "📚 Additional Resources:"
echo "======================="
echo "• OpenAI OAuth Community: https://community.openai.com/t/error-in-oauth-handling-in-custom-gpt/665758"
echo "• OAuth Troubleshooting Guide: https://windowsreport.com/chatgpt-error-oauthcallback/"
echo "• OAuth Token Refresh Guide: https://community.openai.com/t/guide-how-oauth-refresh-tokens-revocation-work-with-gpt-actions/533147"
echo

echo "✨ OAuth should now work correctly with ChatGPT!" 