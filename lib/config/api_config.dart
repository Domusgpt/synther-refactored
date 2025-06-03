/// Configuration for API keys and endpoints
/// 
/// In production, these should be loaded from:
/// - Firebase Remote Config
/// - Environment variables  
/// - Secure key storage
/// 
/// To get API keys:
/// - Hugging Face: Sign up at https://huggingface.co/ and go to Settings > Access Tokens
/// - Gemini: Get API key from https://makersuite.google.com/app/apikey
/// - Groq: Sign up at https://console.groq.com/keys for free API access
/// - Mistral: Get API key from https://console.mistral.ai/api-keys
/// - Replicate: Get API key from https://replicate.com/account/api-tokens
/// - Cohere: Sign up at https://dashboard.cohere.com/api-keys
class ApiConfig {
  // API Keys (replace with secure storage in production)
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  
  // Hugging Face API token
  // Get yours from: https://huggingface.co/settings/tokens
  static const String huggingFaceApiKey = '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';
  
  // Model endpoints
  static const String geminiModel = 'gemini-1.5-flash';
  // Using Mistral 7B which works well for JSON generation
  static const String huggingFaceModel = 'mistralai/Mistral-7B-Instruct-v0.2';
  
  // API base URLs
  static const String geminiApiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String huggingFaceBaseUrl = 'https://api-inference.huggingface.co/models';
  
  // Groq API configuration (free tier available)
  // Get your free API key from: https://console.groq.com/keys
  static const String groqApiKey = 'YOUR_GROQ_API_KEY';
  
  // API Type (choose which one to use)
  static const ApiType defaultApiType = ApiType.huggingFace;
  
  /// Check if API is configured
  static bool get isConfigured {
    switch (defaultApiType) {
      case ApiType.gemini:
        return geminiApiKey != 'YOUR_GEMINI_API_KEY';
      case ApiType.huggingFace:
        return true; // HF has free inference API that doesn't require key for some models
      case ApiType.groq:
        return groqApiKey != 'YOUR_GROQ_API_KEY';
    }
  }
  
  /// Get the full endpoint URL
  static String get geminiEndpoint => '$geminiApiBaseUrl/models/$geminiModel:generateContent';
  
  /// Get the Hugging Face endpoint
  static String get huggingFaceEndpoint => '$huggingFaceBaseUrl/$huggingFaceModel';
}

/// Available API types
enum ApiType {
  gemini,
  huggingFace,
  groq,
}