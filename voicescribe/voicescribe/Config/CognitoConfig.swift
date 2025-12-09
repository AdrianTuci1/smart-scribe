import Foundation

struct CognitoConfig {
    static let userPoolId = "eu-central-1_KUaE0MTcQ" // User Pool ID
    static let clientId = "ar2m2qg3gp4a0b4cld09aegdb" // App Client ID
    static let clientSecret = ""
    static let identityPoolId = "eu-central-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" // Identity Pool ID
    static let region = "eu-central-1" // AWS region
    
    // Cognito Domain Configuration (use the configured hosted/custom domain)
    // For custom domain: https://auth.simplu.io
    // For default domain: https://<prefix>.auth.<region>.amazoncognito.com
    static let cognitoDomain = "https://auth.simplu.io"
    static let redirectUri = "voicescribe://auth" // Custom URL scheme for deep linking
    static let logoutUri = "http://localhost:3000/"
    static let responseType = "code"
    static let scope = "email openid phone"
    
    // API endpoints
    static let apiBaseUrl = "http://localhost:4000/api/v1" // Replace with your API endpoint
    
    // Authentication endpoints
    static let loginEndpoint = "\(apiBaseUrl)/auth/login"
    static let signUpEndpoint = "\(apiBaseUrl)/auth/signup"
    static let confirmSignUpEndpoint = "\(apiBaseUrl)/auth/confirm"
    static let refreshEndpoint = "\(apiBaseUrl)/auth/refresh"
    static let logoutEndpoint = "\(apiBaseUrl)/auth/logout"
}
