//
//  ImageAnalysisService.swift
//  ImageAnalyzer
//
//  Created by s0s08at on 2/23/26.
//

import Foundation
import UIKit
                                                                                                                                                                      
class ImageAnalysisService {
    // ⚠️ In production, store this securely (Keychain)
    private let apiKey = "YOUR_ELEMENT_LLM_GATEWAY_KEY"
    private let endpoint = "https://element-llm-gateway.walmart.com/v1/chat/completions"
                                                                                                                                                                      
    struct AnalysisResult {
        let description: String
        let suggestedActions: [String]
    }
                                                                                                                                                                      
    func analyzeImage(_ image: UIImage) async throws -> AnalysisResult {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }
        let base64Image = imageData.base64EncodedString()
                                                                                                                                                                      
        // Build the request
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": """
                                Analyze this image and provide:
                                1. A brief description (2-3 sentences) of what's in the image
                                2. A list of 3-5 practical actions the user could take based on this image
                                                                                                                                                                      
                                Format your response as JSON:
                                {
                                    "description": "your description here",
                                    "actions": ["action 1", "action 2", "action 3"]
                                }
                                """
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500
        ]
                                                                                                                                                                      
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                                                                                                                                                                      
        let (data, response) = try await URLSession.shared.data(for: request)
                                                                                                                                                                      
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "APIError", code: 2, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
                                                                                                                                                                      
        // Parse response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String ?? ""
                                                                                                                                                                      
        // Parse the JSON content from the model
        return parseAnalysisContent(content)
    }
                                                                                                                                                                      
    private func parseAnalysisContent(_ content: String) -> AnalysisResult {
        // Try to extract JSON from the response
        if let jsonStart = content.firstIndex(of: "{"),
           let jsonEnd = content.lastIndex(of: "}") {
            let jsonString = String(content[jsonStart...jsonEnd])
            if let jsonData = jsonString.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                let description = parsed["description"] as? String ?? "Unable to analyze image"
                let actions = parsed["actions"] as? [String] ?? []
                return AnalysisResult(description: description, suggestedActions: actions)
            }
        }
                                                                                                                                                                      
        // Fallback if JSON parsing fails
        return AnalysisResult(
            description: content,
            suggestedActions: ["Review the image manually"]
        )
    }
} 
