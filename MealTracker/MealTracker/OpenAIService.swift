//
//  OpenAIService.swift
//  MealTracker
//
//  Created by Isaac Restrick on 5/15/23.
//

import Foundation

class OpenAIService: ObservableObject {
    private let apiKey: String
    private let recipeApiUrl = "https://api.openai.com/v1/chat/completions"
    private let imageApiUrl = "https://api.openai.com/v1/images/generations"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateRecipe(description: String, completion: @escaping (Result<String, Error>) -> Void) {
        let conversation = [
            ["role": "user", "content": "I have a meal in mind. It's \(description). Can you suggest a recipe?"],
            ["role": "system", "content": "You are a helpful assistant. Reply with a JSON containing two key/value pairs: 1) 'name': the name of the meal, 2) 'description': a better description of the meal including food items. Should be reasonably concise and fit on a mobile phone"]
        ]
        
        let requestData: [String: Any] = [
            "model": "gpt-4",
            "messages": conversation
        ]
        
        sendRequest(urlString: recipeApiUrl, requestData: requestData) { (result: Result<[String: Any], Error>) in
            switch result {
                case .success(let jsonResponse):
                    if let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API response"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    func generateImage(prompt: String, n: Int, size: String, completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        let requestData: [String: Any] = [
            "prompt": prompt,
            "n": n,
            "size": size
        ]
        
        sendRequest(urlString: imageApiUrl, requestData: requestData) { (result: Result<[String: Any], Error>) in
            switch result {
                case .success(let jsonResponse):
                    if let imageData = jsonResponse["data"] as? [[String: String]] {
                        completion(.success(imageData))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API response"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    private func sendRequest(urlString: String, requestData: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response object"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API returned status code: \(httpResponse.statusCode)"])))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(.success(jsonResponse))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
