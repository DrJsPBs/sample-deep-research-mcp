# ChatGPT OAuth Flow - ASCII Diagram

## 🔄 **Complete OAuth Authentication Flow**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              CHATGPT OAUTH FLOW                                    │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────────────────┐    ┌─────────────┐    ┌─────────────┐
│  ChatGPT    │    │   MCP Server            │    │ User Browser│    │ OAuth Server│
│             │    │ cupcake.onemainarmy.com │    │             │    │             │
└─────────────┘    └─────────────────────────┘    └─────────────┘    └─────────────┘
       │                       │                           │                   │
       │                       │                           │                   │
       │  Phase 1: Discovery & Registration                │                   │
       │───────────────────────│                           │                   │
       │                       │                           │                   │
       │ 1. GET /.well-known/oauth-authorization-server    │                   │
       │───────────────────────│                           │                   │
       │                       │ 200 OK (OAuth config)     │                   │
       │                       │───────────────────────────│                   │
       │                       │                           │                   │
       │ 2. GET /.well-known/mcp/manifest.json             │                   │
       │───────────────────────│                           │                   │
       │                       │ 200 OK (MCP manifest)     │                   │
       │                       │───────────────────────────│                   │
       │                       │                           │                   │
       │ 3. POST /register (OAuth client registration)     │                   │
       │    Client ID: bffb61f7-a897-40bb-8579-2b7436e27ac2│                   │
       │───────────────────────│                           │                   │
       │                       │ 200 OK (Client registered)│                   │
       │                       │───────────────────────────│                   │
       │                       │                           │                   │
       │  Phase 2: Authorization Request                   │                   │
       │───────────────────────│                           │                   │
       │                       │                           │                   │
       │ 4. GET /authorize?response_type=code&client_id=...│                   │
       │    &code_challenge=BSqSWAyqJtJA50LUrwduwOibS5XAuctuSvz3NcQ2whI        │
       │    &code_challenge_method=S256&scope=mcp          │                   │
       │───────────────────────│                           │                   │
       │                       │ 302 Found (Redirect)      │                   │
       │                       │───────────────────────────│                   │
       │                       │                           │                   │
       │  Phase 3: User Authorization                      │                   │
       │───────────────────────│                           │                   │
       │                       │                           │                   │
       │                       │ 5. Redirect to User       │                   │
       │                       │───────────────────────────│                   │
       │                       │                           │ 6. User sees auth │
       │                       │                           │    page & approves│
       │                       │                           │                   │
       │                       │ 7. GET /oauth/callback    │                   │
       │                       │    ?code=xFlYhE6BwO0HmrO7moVCcOx3_VnF3FZT     │
       │                       │    &state=oauth_s_688d6e64f8cc8191b789773d7a93b806│
       │                       │───────────────────────────│                   │
       │                       │ 302 Found (Redirect)      │                   │
       │                       │───────────────────────────│                   │
       │                       │                           │                   │
       │  Phase 4: Token Exchange                          │                   │
       │───────────────────────│                           │                   │
       │                       │                           │                   │
       │ 8. POST /token (Exchange auth code for token)     │                   │
       │    Authorization: Basic <client_credentials>      │                   │
       │    grant_type=authorization_code                  │                   │
       │    code=xFlYhE6BwO0HmrO7moVCcOx3_VnF3FZT         │                   │
       │    redirect_uri=https://chatgpt.com/connector_platform_oauth_redirect│
       │───────────────────────│                           │                   │
       │                       │ 200 OK (Access token)     │                   │
       │                       │ Token: mcp_<32_hex_chars> │                   │
       │                       │ Expires: 24 hours         │                   │
       │                       │───────────────────────────│                   │
       │                       │                           │                   │
       │  Phase 5: Authenticated API Access                │                   │
       │───────────────────────│                           │                   │
       │                       │                           │                   │
       │ 9. GET /sse                                          │                   │
       │    Authorization: Bearer mcp_<token>               │                   │
       │───────────────────────│                           │                   │
       │                       │ 200 OK (SSE connected)    │                   │
       │                       │───────────────────────────│                   │
       │                       │                           │                   │
       │ 10. POST /messages/?session_id=<id>               │                   │
       │     Authorization: Bearer mcp_<token>             │                   │
       │     ListToolsRequest                              │                   │
       │───────────────────────│                           │                   │
       │                       │ 202 Accepted (Tools listed)│                   │
       │                       │───────────────────────────│                   │
       │                       │                           │                   │
       │ 11. POST /messages/?session_id=<id>               │                   │
       │     Authorization: Bearer mcp_<token>             │                   │
       │     CallToolRequest                               │                   │
       │───────────────────────│                           │                   │
       │                       │ 202 Accepted (Tool executed)│                   │
       │                       │───────────────────────────│                   │
       │                       │                           │                   │
```

## 🔐 **Security Flow Details**

### **OAuth 2.0 + PKCE Implementation**
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              SECURITY FEATURES                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

1. PKCE (Proof Key for Code Exchange)
   ├── code_verifier: Generated by ChatGPT (random string)
   ├── code_challenge: SHA256(code_verifier) = BSqSWAyqJtJA50LUrwduwOibS5XAuctuSvz3NcQ2whI
   └── Purpose: Prevents authorization code interception attacks

2. State Parameter
   ├── state: oauth_s_688d6e64f8cc8191b789773d7a93b806
   └── Purpose: Prevents CSRF attacks

3. Secure Token Format
   ├── Prefix: mcp_
   ├── Length: 32 hex characters
   ├── Expiration: 24 hours
   └── No refresh tokens (avoids ChatGPT refresh issues)

4. Session Management
   ├── Session IDs: Unique per conversation
   ├── Token validation: Every request
   └── Automatic expiration: 24 hours
```

## 📊 **Request/Response Flow**

### **Unauthenticated Requests (Blocked)**
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  UNAUTHORIZED ACCESS ATTEMPTS (401 Unauthorized)                                   │
└─────────────────────────────────────────────────────────────────────────────────────┘

GET /sse HTTP/1.1
Host: cupcake.onemainarmy.com
Content-Type: application/json

Response: 401 Unauthorized
WWW-Authenticate: Bearer resource_metadata="https://cupcake.onemainarmy.com/.well-known/oauth-protected-resource"
```

### **Authenticated Requests (Allowed)**
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  AUTHORIZED ACCESS (200 OK / 202 Accepted)                                         │
└─────────────────────────────────────────────────────────────────────────────────────┘

GET /sse HTTP/1.1
Host: cupcake.onemainarmy.com
Authorization: Bearer mcp_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
Content-Type: application/json

Response: 200 OK
```

## 🎯 **Endpoint Protection Matrix**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              ENDPOINT SECURITY                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│  PUBLIC ENDPOINTS (No Authentication Required)                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  GET /.well-known/oauth-authorization-server  → 200 OK                             │
│  GET /.well-known/mcp/manifest.json           → 200 OK                             │
│  GET /.well-known/oauth-protected-resource    → 200 OK                             │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│  OAUTH FLOW ENDPOINTS (Protocol Specific)                                          │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  POST /register                                  → 200 OK (Client registered)       │
│  GET  /authorize?params...                       → 302 Found (Redirect)            │
│  GET  /oauth/callback?code=...&state=...        → 302 Found (Redirect)            │
│  POST /token                                     → 200 OK (Token issued)            │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────┐
│  PROTECTED ENDPOINTS (Authentication Required)                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  GET  /sse                                       → 401 Unauthorized (no token)     │
│  GET  /sse (with Bearer token)                   → 200 OK                          │
│  POST /messages/?session_id=...                  → 401 Unauthorized (no token)     │
│  POST /messages/?session_id=... (with token)     → 202 Accepted                    │
│  POST /tools/*                                   → 401 Unauthorized (no token)     │
│  POST /tools/* (with token)                      → 202 Accepted                    │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 🎉 **Flow Summary**

The OAuth flow is **working correctly and securely**:

1. ✅ **Discovery**: ChatGPT discovers OAuth configuration
2. ✅ **Registration**: ChatGPT registers as OAuth client
3. ✅ **Authorization**: User authorizes ChatGPT access
4. ✅ **Token Exchange**: ChatGPT gets secure access token
5. ✅ **API Access**: ChatGPT uses token for authenticated requests
6. ✅ **Security**: All unauthorized requests are blocked

**Result**: ChatGPT cannot access the MCP server without completing the full OAuth flow. 