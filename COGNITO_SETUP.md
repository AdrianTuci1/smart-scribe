# AWS Cognito Integration Guide

This guide explains how to set up and use AWS Cognito authentication for both Elixir backend and Swift application.

## Overview

The VoiceScribe application now uses AWS Cognito for user authentication, providing secure sign-up, sign-in, and token management. The integration includes:

- User registration and confirmation
- User authentication with JWT tokens
- Token refresh functionality
- Secure API endpoints with token verification
- WebSocket authentication
- Web-based authentication with deep linking

## Current Configuration

The application is configured with the following AWS Cognito settings:

- **User Pool ID**: eu-central-1_KUaE0MTcQ
- **Client ID**: ar2m2qg3gp4a0b4cld09aegdb
- **Region**: eu-central-1
- **Cognito Domain**: https://auth.simplu.io.auth.eu-central-1.amazoncognito.com
- **Redirect URI**: voicescribe://auth (Custom URL scheme for deep linking)
- **Logout URI**: http://localhost:3000/
- **Response Type**: code
- **Scope**: email openid phone

## Deep Linking for Authentication

The application now supports web-based authentication with deep linking, which allows users to authenticate through a browser and be redirected back to the app.

### How It Works

1. User initiates authentication in the app
2. App opens the system browser with the Cognito authorization URL
3. User signs in with their credentials in the browser
4. After successful authentication, Cognito redirects to the custom URL scheme (voicescribe://auth)
5. The app receives the callback, exchanges the authorization code for tokens, and completes the authentication flow

### Configuration Steps

#### 1. Configure Custom URL Scheme

The `Info.plist` file has been updated with the following configuration:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.voicescribe.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>voicescribe</string>
        </array>
    </dict>
</array>
```

#### 2. Update Cognito Configuration

The `CognitoConfig.swift` file has been updated with the custom redirect URI:

```swift
static let redirectUri = "voicescribe://auth" // Custom URL scheme for deep linking
```

#### 3. Handle URL Callbacks

The `WisprFlowApp.swift` file now includes URL handling:

```swift
.onOpenURL { url in
    // Handle deep linking URLs
    handleIncomingURL(url)
}
```

#### 4. Web-based Authentication

The `AuthService.swift` file now includes methods for web-based authentication:

```swift
/// Initiates web-based authentication with Cognito
func signInWithWebBrowser() {
    // Construct authorization URL
    let authURL = constructAuthURL()
    
    // Open URL in default browser
    if let url = URL(string: authURL) {
        NSWorkspace.shared.open(url)
    }
}

/// Handles callback from Cognito after authentication
func handleAuthCallback(url: URL) async -> Bool {
    // Extract authorization code from URL
    // Exchange code for tokens
    // Update authentication state
}
```

### Using Web-based Authentication

To use web-based authentication in your UI:

```swift
Button("Sign In with Browser") {
    Task {
        await AuthService.shared.signInWithWebBrowser()
    }
}
```

### Testing Deep Linking

1. Build and run the app
2. Click the "Sign In with Browser" button
3. The system browser should open with the Cognito login page
4. After successful authentication, the app should be brought to the foreground
5. Check the console for authentication success/failure messages

## AWS Cognito Setup

### 1. Create a User Pool

1. Go to AWS Cognito console
2. Click "Create a user pool"
3. Configure the following settings:
   - **Pool name**: VoiceScribeUsers
   - **Standard attributes**: Email (required)
   - **Password policy**: Minimum length 8, require numbers, special characters
   - **MFA and verification**: No MFA
   - **User account recovery**: Enable email-based recovery
   - **App clients**: Create a new app client
     - App client name: VoiceScribeApp
     - Uncheck "Generate client secret" for development (check for production)
     - Enable "ALLOW_USER_PASSWORD_AUTH" flow
     - Add custom callback URL: `voicescribe://auth`
4. Review and create the user pool
5. Note down the **User pool ID** and **App client ID**

### 2. Create an Identity Pool (Optional)

If you need AWS credentials for accessing other AWS services:

1. Go to Amazon Cognito console
2. Click "Create new identity pool"
3. Give it a name (e.g., VoiceScribeIdentityPool)
4. Select "Enable access to unauthenticated identities" if needed
5. Under "Authentication providers", expand "Cognito" and enter your User Pool ID and App Client ID
6. Create the pool
7. Note down the **Identity pool ID**

## Backend Configuration (Elixir)

### 1. Environment Variables

Create a `.env` file in the `elixir_voicescribe_backend` directory with the following variables:

```env
# AWS Configuration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=eu-central-1

# AWS Cognito Configuration
COGNITO_USER_POOL_ID=eu-central-1_KUaE0MTcQ
COGNITO_CLIENT_ID=ar2m2qg3gp4a0b4cld09aegdb
COGNITO_CLIENT_SECRET=your_client_secret
COGNITO_IDENTITY_POOL_ID=eu-central-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# JWT Configuration
JWT_ISSUER=https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_KUaE0MTcQ

# Cognito Domain Configuration
COGNITO_DOMAIN=https://auth.simplu.io.auth.eu-central-1.amazoncognito.com
COGNITO_REDIRECT_URI=voicescribe://auth
COGNITO_LOGOUT_URI=http://localhost:3000/
```

### 2. Install Dependencies

```bash
cd elixir_voicescribe_backend
mix deps.get
```

### 3. Start Server

```bash
mix phx.server
```

## Swift Application Configuration

### 1. Update CognitoConfig.swift

The `CognitoConfig.swift` file has been updated with the following settings:

```swift
struct CognitoConfig {
    static let userPoolId = "eu-central-1_KUaE0MTcQ" // User Pool ID
    static let clientId = "ar2m2qg3gp4a0b4cld09aegdb" // App Client ID
    static let clientSecret = "your_client_secret" // App Client Secret (if applicable)
    static let identityPoolId = "eu-central-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" // Identity Pool ID
    static let region = "eu-central-1" // AWS region
    
    // Cognito Domain Configuration
    static let cognitoDomain = "https://auth.simplu.io.auth.eu-central-1.amazoncognito.com"
    static let redirectUri = "voicescribe://auth" // Custom URL scheme for deep linking
    static let logoutUri = "http://localhost:3000/"
    static let responseType = "code"
    static let scope = "email openid phone"
    
    // API endpoints
    static let apiBaseUrl = "http://localhost:4000/api/v1" // Replace with your API endpoint
}
```

### 2. Add AWS Amplify Dependencies

Add the following dependencies to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/amplify-aws/amplify-swift.git", from: "2.0.0"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0")
]
```

### 3. Configure URL Scheme

The `Info.plist` file has been updated with the custom URL scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.voicescribe.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>voicescribe</string>
        </array>
    </dict>
</array>
```

### 4. Build and Run

Build and run the Swift application:

```bash
cd voicescribe
xcodebuild -project voicescribe.xcodeproj -scheme voicescribe build
```

## Authentication Flow

### 1. Web-based User Authentication

```swift
// Swift
// Initiate web-based authentication
await AuthService.shared.signInWithWebBrowser()

// The app will handle the callback automatically
```

### 2. Direct User Authentication

```swift
// Swift
let success = await AuthService.shared.signIn(
    username: "user@example.com",
    password: "SecurePassword123!"
)

if success {
    // User is authenticated, token is available in AuthService.shared.token
}
```

### 3. User Registration

```swift
// Swift
let success = await AuthService.shared.signUp(
    username: "user@example.com",
    email: "user@example.com",
    password: "SecurePassword123!"
)

if success {
    // User needs to confirm their email
    let confirmed = await AuthService.shared.confirmSignUp(
        for: "user@example.com",
        with: "123456" // Confirmation code from email
    )
}
```

### 4. API Requests

All API requests now include the JWT token in the Authorization header:

```swift
// Swift
let notes = try await APIService.shared.fetchNotes()
```

### 5. WebSocket Connection

The WebSocket connection also includes the JWT token:

```swift
// Swift
WebSocketService.shared.connectToTranscription()
```

## API Endpoints

### Authentication Endpoints

- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/signup` - User registration
- `POST /api/v1/auth/confirm` - Confirm user registration
- `POST /api/v1/auth/refresh` - Refresh JWT token
- `POST /api/v1/auth/logout` - User logout

### Protected Endpoints

All endpoints under `/api/v1` (except authentication endpoints) require a valid JWT token:

- `GET /api/v1/notes` - Get user notes
- `POST /api/v1/notes` - Create a new note
- `DELETE /api/v1/notes/:id` - Delete a note
- `GET /api/v1/config/snippets` - Get user snippets
- `POST /api/v1/config/snippets` - Save user snippets
- And more...

## Testing

### 1. Test User Registration

```bash
curl -X POST http://localhost:4000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test@example.com",
    "email": "test@example.com",
    "password": "Password123!"
  }'
```

### 2. Test User Login

```bash
curl -X POST http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test@example.com",
    "password": "Password123!"
  }'
```

### 3. Test Protected Endpoint

```bash
# Replace YOUR_JWT_TOKEN with the token from the login response
curl -X GET http://localhost:4000/api/v1/notes \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 4. Test Deep Linking

1. Build and run the app
2. Click the "Sign In with Browser" button
3. The system browser should open with the Cognito login page
4. After successful authentication, the app should be brought to the foreground
5. Check the console for authentication success/failure messages

## Troubleshooting

### Common Issues

1. **Invalid JWT Token**
   - Ensure the token is not expired
   - Check that the token is correctly formatted
   - Verify the User Pool ID and region in the configuration

2. **Cognito Configuration Errors**
   - Verify that the User Pool ID and Client ID are correct
   - Ensure the App Client is configured with the correct authentication flow
   - Check that AWS credentials have the necessary permissions

3. **Deep Linking Issues**
   - Verify the custom URL scheme is correctly configured in Info.plist
   - Ensure the redirect URI in Cognito matches the custom URL scheme
   - Check that the URL handler is properly implemented in the app

4. **Network Issues**
   - Ensure the backend server is running
   - Check that the API base URL is correct
   - Verify network connectivity

### Debugging

Enable debug logging in the Elixir backend:

```elixir
config :logger, level: :debug
```

Enable debug logging in the Swift app:

```swift
// In your AppDelegate or main setup
Amplify.Logging.logLevel = .verbose
```

## Security Considerations

1. **Client Secret**: For production, always use a client secret and store it securely
2. **Token Storage**: Store tokens securely in the keychain on iOS
3. **HTTPS**: Always use HTTPS in production
4. **Token Refresh**: Implement proper token refresh to avoid expired tokens
5. **Password Policy**: Enforce strong password policies in Cognito
6. **CSRF Protection**: Use state parameters in OAuth flows to prevent CSRF attacks

## Next Steps

1. Implement social sign-in options (Google, Apple, etc.)
2. Add multi-factor authentication (MFA)
3. Implement role-based access control
4. Add user profile management
5. Implement password reset functionality
6. Add biometric authentication for enhanced security
