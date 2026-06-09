import Foundation

struct AnthropicClient: Sendable {
    static let shared = AnthropicClient()

    private let model = "claude-sonnet-4-6"
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!

    struct Message: Codable {
        let role: String
        let content: MessageContent
    }

    enum MessageContent: Codable {
        case text(String)
        case blocks([ContentBlock])

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .text(let s): try container.encode(s)
            case .blocks(let b): try container.encode(b)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let s = try? container.decode(String.self) {
                self = .text(s)
            } else {
                self = .blocks(try container.decode([ContentBlock].self))
            }
        }
    }

    struct ContentBlock: Codable {
        let type: String
        let text: String
        var cacheControl: CacheControl?

        enum CodingKeys: String, CodingKey {
            case type, text
            case cacheControl = "cache_control"
        }
    }

    struct CacheControl: Codable {
        let type: String
    }

    struct Request: Codable {
        let model: String
        let maxTokens: Int
        let system: String?
        let messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case system, messages
        }
    }

    struct Response: Codable {
        let content: [ResponseContent]
    }

    struct ResponseContent: Codable {
        let type: String
        let text: String
    }

    private func apiKey() -> String? {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".my-mind")
            .appendingPathComponent("config.json")

        if let data = try? Data(contentsOf: configPath),
           let config = try? JSONDecoder().decode([String: String].self, from: data) {
            if let key = config["apiKey"] ?? config["anthropic_api_key"] {
                return key
            }
        }
        return ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
            ?? ProcessInfo.processInfo.environment["ANTHROPIC_AUTH_TOKEN"]
    }

    private let ollamaURL = URL(string: "http://localhost:11434/api/chat")!
    private let ollamaModel = "llama3.2"

    private func ollamaAvailable() async -> Bool {
        guard let url = URL(string: "http://localhost:11434/api/tags") else { return false }
        guard let (_, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200 else { return false }
        return true
    }

    private func sendViaOllama(system: String, userMessage: String) async throws -> String {
        let body: [String: Any] = [
            "model": ollamaModel,
            "stream": false,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": userMessage]
            ]
        ]
        var request = URLRequest(url: ollamaURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "Ollama error")
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.emptyResponse
        }
        return content
    }

    func send(system: String, userMessage: String, maxTokens: Int = 1024) async throws -> String {
        guard let key = apiKey() else {
            if await ollamaAvailable() {
                return try await sendViaOllama(system: system, userMessage: userMessage)
            }
            throw AIError.noAPIKey
        }

        let body = Request(
            model: model,
            maxTokens: maxTokens,
            system: system,
            messages: [Message(role: "user", content: .text(userMessage))]
        )

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AIError.apiError(statusCode: statusCode, message: body)
        }

        let apiResponse = try JSONDecoder().decode(Response.self, from: data)
        guard let text = apiResponse.content.first?.text else {
            throw AIError.emptyResponse
        }
        return text
    }

    func sendWithCache(system: String, cachedContent: String, userMessage: String, maxTokens: Int = 1024) async throws -> String {
        guard let key = apiKey() else {
            if await ollamaAvailable() {
                return try await sendViaOllama(system: system, userMessage: cachedContent + "\n\n" + userMessage)
            }
            throw AIError.noAPIKey
        }

        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    ["type": "text", "text": cachedContent, "cache_control": ["type": "ephemeral"]],
                    ["type": "text", "text": userMessage]
                ]
            ]
        ]

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": messages
        ]

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let respBody = String(data: data, encoding: .utf8) ?? ""
            throw AIError.apiError(statusCode: statusCode, message: respBody)
        }

        let apiResponse = try JSONDecoder().decode(Response.self, from: data)
        guard let text = apiResponse.content.first?.text else {
            throw AIError.emptyResponse
        }
        return text
    }
}

enum AIError: Error, LocalizedError {
    case noAPIKey
    case apiError(statusCode: Int, message: String)
    case emptyResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key found. Add anthropic_api_key to ~/.my-mind/config.json"
        case .apiError(let code, let msg): return "API error (\(code)): \(msg)"
        case .emptyResponse: return "Empty response from API"
        case .parseError: return "Failed to parse AI response"
        }
    }
}
