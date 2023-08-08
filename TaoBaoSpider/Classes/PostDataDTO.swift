//
//  PostDataDTO.swift
//  WKWebViewDemo
//
//  Created by Alan Ge on 2023/7/9.
//

import Foundation

class PostDataDTO {
    static var shared = PostDataDTO()
    public let api = "http://106.13.235.245/"
    private let currentUserId = "\(Authorization.default.user?.id ?? "")_\(NSObject.Tenant)"
    
    func postData(path: String, content: String, type: String? = nil, month: String? = nil) {
        var parameters = ["currentUserId": self.currentUserId,
                          "body": content]
        if let type = type {
            parameters["type"] = type
        }
        if let month = month {
            parameters["month"] = month
        }
        log.info("path:\(path)")
        log.info("parameters:\(parameters)")
        postData(path: path, parameters: parameters)
    }
    
    func postData(path: String, parameters: [String: Any]) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let `self` = self else { return }
            if let url = URL(string: self.api + path) {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                do {
                    let data = try JSONSerialization.data(withJSONObject: parameters)
                    if request.value(forHTTPHeaderField: "Content-Type") == nil {
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    }
                    request.httpBody = data
                } catch {
                    log.info(error)
                }
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data, let _:URLResponse = response, error == nil else {
                        return
                    }
                    let dataString = self.DataToObject(data)
                    log.info("dataString is \(dataString ?? "")\npath:\(path)")
                }
                task.resume()
            }
        }
    }
    
    func DataToObject(_ data: Data) -> Any? {
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            return object
        } catch {
            log.info(error)
        }
        return nil
    }
}
