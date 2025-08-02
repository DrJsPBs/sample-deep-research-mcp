#!/usr/bin/env python3
"""
Custom Context7 MCP Server with OAuth middleware
Implements RFC 9728 for OAuth discovery and 401 challenges
"""

import json
import logging
import time
from pathlib import Path
from secrets import token_hex, token_urlsafe
from typing import override

from fastmcp.server import FastMCP
from fastmcp.server.auth.auth import ClientRegistrationOptions, OAuthProvider, RevocationOptions
from mcp.server.auth.provider import (
    AccessToken,
    AuthorizationCode,
    AuthorizationParams,
    RefreshToken,
    construct_redirect_uri,
)
from mcp.shared.auth import OAuthClientInformationFull, OAuthToken
from pydantic import BaseModel, AnyHttpUrl
from starlette.exceptions import HTTPException
from starlette.requests import Request
from starlette.responses import JSONResponse, RedirectResponse, Response
from starlette.middleware.base import BaseHTTPMiddleware

RECORDS = json.loads(Path(__file__).with_name("records.json").read_text())
LOOKUP = {r["id"]: r for r in RECORDS}

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# OAuth configuration
MCP_SCOPE = "mcp"
MCP_ISSUER_URL = "https://cupcake.onemainarmy.com"
AUTH_SERVER_URL = "https://oauth.onemainarmy.com"

class AuthenticationMiddleware(BaseHTTPMiddleware):
    """Custom authentication middleware to ensure all protected endpoints require OAuth"""
    
    def __init__(self, app, oauth_provider):
        super().__init__(app)
        self.oauth_provider = oauth_provider
    
    async def dispatch(self, request: Request, call_next):
        # Log all requests for debugging
        logger.info(f"Request: {request.method} {request.url.path} - Headers: {dict(request.headers)}")
        
        # Public endpoints that don't require authentication
        public_endpoints = [
            "/.well-known/oauth-protected-resource",
            "/.well-known/oauth-authorization-server", 
            "/.well-known/mcp/manifest.json",
            "/oauth/callback"
        ]
        
        # Check if this is a public endpoint
        if request.url.path in public_endpoints:
            logger.info(f"Public endpoint accessed: {request.url.path}")
            return await call_next(request)
        
        # For SSE endpoint, require authentication
        if request.url.path == "/sse":
            auth_header = request.headers.get("authorization")
            if not auth_header:
                logger.warning(f"SSE endpoint accessed without authentication: {request.url.path}")
                return Response(
                    content="Unauthorized: OAuth token required",
                    status_code=401,
                    headers={
                        "WWW-Authenticate": f'Bearer resource_metadata="{MCP_ISSUER_URL}/.well-known/oauth-protected-resource"',
                        "Content-Type": "text/plain"
                    }
                )
            
            # Validate token
            if not auth_header.startswith("Bearer "):
                logger.warning(f"Invalid Authorization header format: {auth_header[:20]}...")
                return Response(
                    content="Unauthorized: Invalid token format",
                    status_code=401,
                    headers={
                        "WWW-Authenticate": f'Bearer resource_metadata="{MCP_ISSUER_URL}/.well-known/oauth-protected-resource"',
                        "Content-Type": "text/plain"
                    }
                )
            
            token = auth_header.split(" ", 1)[1]
            # Validate token with OAuth provider
            access_token = await self.oauth_provider.load_access_token(token)
            if not access_token:
                logger.warning(f"Invalid token provided: {token[:10]}...")
                return Response(
                    content="Unauthorized: Invalid token",
                    status_code=401,
                    headers={
                        "WWW-Authenticate": f'Bearer error="invalid_token", resource_metadata="{MCP_ISSUER_URL}/.well-known/oauth-protected-resource"',
                        "Content-Type": "text/plain"
                    }
                )
            
            logger.info(f"SSE endpoint accessed with valid token: {token[:10]}...")
        
        # For all other endpoints, let FastMCP handle authentication
        return await call_next(request)

class CustomOAuthProvider(OAuthProvider):
    """Custom OAuth provider that integrates with the existing OAuth server"""
    
    def __init__(self):
        super().__init__(
            issuer_url=MCP_ISSUER_URL,  # Use MCP server as issuer for better ChatGPT compatibility
            client_registration_options=ClientRegistrationOptions(
                enabled=True, 
                valid_scopes=[MCP_SCOPE], 
                default_scopes=[MCP_SCOPE]
            ),
            required_scopes=[MCP_SCOPE],
        )
        
        self.auth_codes: dict[str, AuthorizationCode] = {}
        self.tokens: dict[str, AccessToken] = {}
        self.state_mapping: dict[str, dict[str, str]] = {}
        self.clients: dict[str, OAuthClientInformationFull] = {}

    @override
    async def get_client(self, client_id: str) -> OAuthClientInformationFull | None:
        """Retrieve an OAuth client by its ID."""
        return self.clients.get(client_id)

    @override
    async def register_client(self, client_info: OAuthClientInformationFull) -> None:
        """Register a new OAuth client."""
        logger.info(f"Registering OAuth client: {client_info.client_id}")
        self.clients[client_info.client_id] = client_info

    @override
    async def authorize(self, client: OAuthClientInformationFull, params: AuthorizationParams) -> str:
        """Generate an authorization URL for OAuth flow."""
        state = params.state or token_urlsafe(32)

        self.state_mapping[state] = {
            "client_id": client.client_id,
            "code_challenge": params.code_challenge,
            "redirect_uri_provided_explicitly": str(params.redirect_uri_provided_explicitly),
            "redirect_uri": str(params.redirect_uri),
        }

        # For ChatGPT compatibility, use a simpler OAuth flow
        # Create a direct authorization URL that ChatGPT can handle
        auth_params = {
            "client_id": client.client_id,
            "redirect_uri": f"{MCP_ISSUER_URL}/oauth/callback",
            "response_type": "code",
            "state": state,
            "scope": " ".join(params.scopes or [MCP_SCOPE]),
        }

        # If PKCE is used, add code_challenge
        if params.code_challenge:
            auth_params["code_challenge"] = params.code_challenge
            auth_params["code_challenge_method"] = "S256"

        return construct_redirect_uri(f"{AUTH_SERVER_URL}/authorize", **auth_params)

    @override
    async def load_authorization_code(
        self, client: OAuthClientInformationFull, authorization_code: str
    ) -> AuthorizationCode | None:
        """Retrieve an authorization code."""
        code = self.auth_codes.get(authorization_code)
        if code and code.client_id == client.client_id:
            return code
        return None

    @override
    async def exchange_authorization_code(
        self, client: OAuthClientInformationFull, authorization_code: AuthorizationCode
    ) -> OAuthToken:
        """Exchange an authorization code for a token."""
        if authorization_code.code not in self.auth_codes:
            raise ValueError("Invalid authorization code")

        # Create a long-lived token for ChatGPT (24 hours)
        mcp_token = f"mcp_{token_hex(32)}"
        expires_in = 86400  # 24 hours

        self.tokens[mcp_token] = AccessToken(
            token=mcp_token,
            client_id=client.client_id,
            scopes=authorization_code.scopes,
            expires_at=int(time.time()) + expires_in,
        )

        del self.auth_codes[authorization_code.code]

        return OAuthToken(
            access_token=mcp_token,
            token_type="bearer",
            expires_in=expires_in,
            scope=" ".join(authorization_code.scopes),
            # Don't include refresh_token to avoid ChatGPT refresh issues
        )

    @override
    async def load_access_token(self, token: str) -> AccessToken | None:
        """Load and validate an access token."""
        access_token = self.tokens.get(token)
        if not access_token:
            return None

        if access_token.expires_at and access_token.expires_at < time.time():
            del self.tokens[token]
            return None

        return access_token

    @override
    async def revoke_token(self, token: AccessToken | RefreshToken) -> None:
        """Revoke a token."""
        if token.token in self.tokens:
            del self.tokens[token.token]

    @override
    async def load_refresh_token(self, client: OAuthClientInformationFull, refresh_token: str) -> RefreshToken | None:
        # Don't implement refresh tokens to avoid ChatGPT issues
        return None

    @override
    async def exchange_refresh_token(
        self, client: OAuthClientInformationFull, refresh_token: RefreshToken, scopes: list[str]
    ) -> OAuthToken:
        # Don't implement refresh tokens to avoid ChatGPT issues
        raise NotImplementedError()

    async def handle_oauth_callback(self, code: str, state: str) -> str:
        """Handle OAuth callback."""
        state_data = self.state_mapping.get(state)
        if not state_data:
            raise HTTPException(400, "Invalid state parameter")

        redirect_uri = state_data["redirect_uri"]
        code_challenge = state_data["code_challenge"]
        redirect_uri_provided_explicitly = state_data["redirect_uri_provided_explicitly"] == "True"
        client_id = state_data["client_id"]

        # Create MCP authorization code
        new_code = f"mcp_{token_hex(16)}"
        auth_code = AuthorizationCode(
            code=new_code,
            client_id=client_id,
            redirect_uri=AnyHttpUrl(redirect_uri),
            redirect_uri_provided_explicitly=redirect_uri_provided_explicitly,
            expires_at=time.time() + 300,  # 5 minutes
            scopes=[MCP_SCOPE],
            code_challenge=code_challenge,
        )
        self.auth_codes[new_code] = auth_code

        del self.state_mapping[state]
        return construct_redirect_uri(redirect_uri, code=new_code, state=state)

class SearchResult(BaseModel):
    id: str
    title: str
    text: str

class SearchResultPage(BaseModel):
    results: list[SearchResult]

class FetchResult(BaseModel):
    id: str
    title: str
    text: str
    url: str | None = None
    metadata: dict[str, str] | None = None

def create_server():
    # Create OAuth provider
    oauth_provider = CustomOAuthProvider()
    
    # Create FastMCP server with authentication
    mcp = FastMCP(name="Cupcake MCP", instructions="Search cupcake orders", auth=oauth_provider)
    
    # ✅ CRITICAL FIX: Apply authentication middleware using the correct FastMCP method
    # FastMCP handles middleware differently - the OAuth provider is already integrated
    # The authentication is handled by FastMCP's built-in OAuth integration

    @mcp.custom_route("/.well-known/oauth-protected-resource", methods=["GET"])
    async def oauth_protected_resource(request):
        """OAuth protected resource metadata endpoint"""
        return JSONResponse({
            "resource": MCP_ISSUER_URL,
            "authorization_servers": [MCP_ISSUER_URL],  # Use MCP server as auth server
            "bearer_methods_supported": ["authorization_header"]
        })

    @mcp.custom_route("/.well-known/oauth-authorization-server", methods=["GET"])
    async def oauth_authorization_server(request):
        """OAuth authorization server metadata endpoint"""
        return JSONResponse({
            "issuer": MCP_ISSUER_URL,  # Use MCP server as issuer
            "authorization_endpoint": f"{MCP_ISSUER_URL}/authorize",
            "token_endpoint": f"{MCP_ISSUER_URL}/token",
            "registration_endpoint": f"{MCP_ISSUER_URL}/register",
            "jwks_uri": f"{MCP_ISSUER_URL}/jwks.json",
            "scopes_supported": [MCP_SCOPE],
            "response_types_supported": ["code"],
            "grant_types_supported": ["authorization_code"],
            "token_endpoint_auth_methods_supported": ["client_secret_post"],
            "code_challenge_methods_supported": ["S256"]
        })

    @mcp.custom_route("/.well-known/mcp/manifest.json", methods=["GET"])
    async def mcp_manifest(request):
        """MCP manifest endpoint for discovery"""
        return JSONResponse({
            "schemaVersion": "2024-11-05",
            "nameForHuman": "Cupcake MCP",
            "nameForModel": "cupcake_mcp",
            "descriptionForHuman": "Search and retrieve cupcake orders with OAuth authentication",
            "descriptionForModel": "Search and retrieve cupcake orders. Requires OAuth authentication.",
            "auth": {
                "type": "oauth",
                "authorization_server": MCP_ISSUER_URL,  # Use MCP server as auth server
                "client_registration": f"{MCP_ISSUER_URL}/register"
            },
            "api": {
                "type": "openapi",
                "url": f"{MCP_ISSUER_URL}/openapi.json"
            },
            "endpoints": ["/sse"]
        })

    # ✅ CRITICAL FIX: Remove the broken SSE endpoint override
    # Let FastMCP handle the SSE endpoint with proper OAuth authentication

    @mcp.custom_route("/oauth/callback", methods=["GET"])
    async def oauth_callback_handler(request: Request) -> Response:
        """Handle OAuth callback from authorization server"""
        code = request.query_params.get("code")
        state = request.query_params.get("state")

        if not code or not state:
            raise HTTPException(400, "Missing code or state parameter")

        try:
            redirect_uri = await oauth_provider.handle_oauth_callback(code, state)
            return RedirectResponse(status_code=302, url=redirect_uri)
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"OAuth callback error: {e}")
            return JSONResponse(
                status_code=500,
                content={
                    "error": "server_error",
                    "error_description": "Unexpected error during OAuth callback",
                },
            )

    @mcp.tool()
    async def search(query: str) -> SearchResultPage:
        """
        Search for cupcake orders – keyword match.
        Requires OAuth token for access.

        Returns a SearchResultPage containing a list of SearchResult items.
        """
        toks = query.lower().split()
        results: list[SearchResult] = []
        for r in RECORDS:
            hay = " ".join(
                [
                    r.get("title", ""),
                    r.get("text", ""),
                    " ".join(r.get("metadata", {}).values()),
                ]
            ).lower()
            if any(t in hay for t in toks):
                results.append(
                    SearchResult(id=r["id"], title=r.get("title", ""), text=r.get("text", ""))
                )

        return SearchResultPage(results=results)

    @mcp.tool()
    async def fetch(id: str) -> FetchResult:
        """
        Fetch a cupcake order by ID.
        Requires OAuth token for access.

        Returns a FetchResult model.
        """
        if id not in LOOKUP:
            raise ValueError("unknown id")

        r = LOOKUP[id]
        return FetchResult(
            id=r["id"],
            title=r.get("title", ""),
            text=r.get("text", ""),
            url=r.get("url"),
            metadata=r.get("metadata"),
        )

    return mcp


if __name__ == "__main__":
    # Run the FastMCP server with built-in OAuth authentication
    server = create_server()
    server.run(transport="sse", host="0.0.0.0", port=8090)
