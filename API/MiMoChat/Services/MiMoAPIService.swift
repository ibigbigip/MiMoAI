//
//  MiMoAPIService.swift
//  MiMoChat
//
//  小米MIMO API服务 - 支持流式输出
//

import Foundation

class MiMoAPIService: ObservableObject {
    // API Key 留空，请用户在设置中填写自己的 API Key
    // 申请地址: https://platform.xiaomimimo.com
    static let defaultAPIKey = ""
    
    @Published var apiKey: String = defaultAPIKey
    @Published var model: String = "mimo-v2-flash"
    @Published var systemPrompt: String = "你是小米MIMO AI助手。"
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 2048
    @Published var enableThinking: Bool = true
    @Published var debugLog: String = ""
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    func saveSettings() {
        userDefaults.set(apiKey, forKey: "api_key")
        userDefaults.set(model, forKey: "model")
        userDefaults.set(enableThinking, forKey: "enable_thinking")
    }
    
    func loadSettings() {
        if let key = userDefaults.string(forKey: "api_key"), !key.isEmpty {
            apiKey = key
        }
        enableThinking = userDefaults.object(forKey: "enable_thinking") as? Bool ?? true
    }
    
    private func log(_ message: String) {
        print(message)
        DispatchQueue.main.async {
            self.debugLog += message + "\n"
        }
    }
    
    // 流式请求 - 动态更新内容和思考过程
    func sendMessageStreaming(
        messages: [Message],
        onThinking: @escaping (String) -> Void,
        onContent: @escaping (String) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        log("🚀 开始流式请求...")
        
        guard let url = URL(string: "https://api.xiaomimimo.com/v1/chat/completions") else {
            onComplete(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL无效"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120
        
        var apiMessages: [[String: String]] = []
        if !systemPrompt.isEmpty {
            apiMessages.append(["role": "system", "content": systemPrompt])
        }
        for msg in messages {
            apiMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }
        
        var body: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "stream": true,  // 启用流式
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        
        if enableThinking {
            body["enable_thinking"] = true
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            onComplete(error)
            return
        }
        
        log("📤 发送流式请求...")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                self?.log("❌ 网络错误: \(error.localizedDescription)")
                DispatchQueue.main.async { onComplete(error) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async { onComplete(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效响应"])) }
                return
            }
            
            self?.log("📡 状态码: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200, let data = data else {
                let errorStr = data.flatMap { String(data: $0, encoding: .utf8) } ?? "未知错误"
                DispatchQueue.main.async { onComplete(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorStr])) }
                return
            }
            
            // 解析SSE数据
            let dataString = String(data: data, encoding: .utf8) ?? ""
            var fullContent = ""
            var fullThinking = ""
            
            let lines = dataString.components(separatedBy: "\n")
            for line in lines {
                if line.hasPrefix("data: ") {
                    let jsonStr = String(line.dropFirst(6))
                    if jsonStr == "[DONE]" { continue }
                    
                    if let jsonData = jsonStr.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let delta = choices.first?["delta"] as? [String: Any] {
                        
                        // 思考内容
                        if let reasoning = delta["reasoning_content"] as? String {
                            fullThinking += reasoning
                            DispatchQueue.main.async { onThinking(fullThinking) }
                        }
                        
                        // 回复内容
                        if let content = delta["content"] as? String {
                            fullContent += content
                            DispatchQueue.main.async { onContent(fullContent) }
                        }
                    }
                }
            }
            
            self?.log("✅ 流式完成")
            DispatchQueue.main.async { onComplete(nil) }
        }
        
        task.resume()
    }
    
    // 非流式请求（备用）
    func sendMessage(messages: [Message], completion: @escaping (Result<(content: String, thinking: String?), Error>) -> Void) {
        guard let url = URL(string: "https://api.xiaomimimo.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL无效"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120
        
        var apiMessages: [[String: String]] = []
        if !systemPrompt.isEmpty {
            apiMessages.append(["role": "system", "content": systemPrompt])
        }
        for msg in messages {
            apiMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }
        
        var body: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "stream": false,
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        
        if enableThinking {
            body["enable_thinking"] = true
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "请求失败"]))) }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                let thinking = message["reasoning_content"] as? String
                DispatchQueue.main.async { completion(.success((content, thinking))) }
            } else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "解析失败"]))) }
            }
        }.resume()
    }
}
