// File: Sources/PrototypingOpenAIClient/PrototypingOpenAIClient.swift
import Foundation

// MARK: - Constants

/// The API key for authenticating requests to the OpenAI API.
private let API_KEY = "your-api-key-here"

/// The model to use for generating responses.
private let MODEL = "gpt-3.5-turbo"

/// The default system prompt to set the behavior of the AI assistant.
private let DEFAULT_SYSTEM_PROMPT = "You are a helpful assistant."

/// The base URL for the OpenAI API chat completions endpoint.
private let BASE_URL = "https://api.openai.com/v1/chat/completions"

// MARK: - Response Models

/// Represents the full response from the OpenAI API.
public struct OpenAIResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage
}

/// Represents a single choice in the API response.
public struct Choice: Codable {
    public let index: Int
    public let message: Message
    public let finishReason: String

    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }

    /// Represents a message in the conversation.
    public struct Message: Codable {
        public let role: String
        public let content: String
    }
}

/// Represents the token usage information in the API response.
public struct Usage: Codable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Error Handling

/// Represents possible errors that can occur when interacting with the OpenAI API.
public enum OpenAIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
}

// MARK: - Main Client

/// The main client for interacting with the OpenAI API.
public class PrototypingOpenAIClient {

    /// Initializes a new instance of the PrototypingOpenAIClient.
    public init() {}

    /// Generates a response from the OpenAI API based on the given prompt and optional system prompt.
    /// - Parameters:
    ///   - prompt: The user's input prompt.
    ///   - systemPrompt: An optional system prompt to override the default. If nil, the default system prompt will be used.
    /// - Returns: An OpenAIResponse object containing the API's response.
    /// - Throws: An OpenAIError if there's an issue with the request or response.
    public func generateResponse(prompt: String, systemPrompt: String? = nil) async throws -> OpenAIResponse {
        // Ensure the base URL is valid
        guard let url = URL(string: BASE_URL) else {
            throw OpenAIError.invalidURL
        }

        // Prepare the API request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(API_KEY)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Use the provided system prompt or fall back to the default
        let finalSystemPrompt = systemPrompt ?? DEFAULT_SYSTEM_PROMPT

        // Prepare the request body
        let body: [String: Any] = [
            "model": MODEL,
            "messages": [
                ["role": "system", "content": finalSystemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        // Serialize the body to JSON
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Send the request and await the response
        let (data, _) = try await URLSession.shared.data(for: request)

        // Decode the response
        let decoder = JSONDecoder()
        return try decoder.decode(OpenAIResponse.self, from: data)
    }
}
