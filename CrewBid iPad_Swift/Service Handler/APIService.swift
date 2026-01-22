//
//  APIService.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/05/25.
//

import Foundation

enum Errors: Error {
    case invalidURL
    case invalidParameters
    case invalidResponse
    case noData
    case decodingError
    case encodingError
    case unauthorized(message: String)
    case timeout
    case unzipFailed
    case noBidData(filename:String)
    case emptyData
    case networkError
    case other(Error)
    case httpStatus(Int, Data?)
}

enum HTTPMethod: String {
    case GET
    case POST
}



// By Raja
// Update this class for common API call and move all these function to corresponding viewModel.

extension Errors {
    var localizedDescriptionString: String {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .noData:
            return "No data received."
        case .decodingError:
            return "Failed to decode the response."
        case .unauthorized(let message):
            return message
        case .timeout:
            return "Request timed out."
        case .unzipFailed:
            return "Failed to Unzip the File"
        case .other(let err):
            return err.localizedDescription
        case .invalidParameters:
            return "Invalid Parameters"
        case .invalidResponse:
            return "Invalid Response"
        case .emptyData:
            return "Empty Data"
        case .encodingError:
            return "Failed to encode the request"
        case .networkError:
            return "A network error occurred. Please check your connection and try again."
        case .httpStatus(let code, let data):

            // If server sent a message, show it AS-IS
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                let message = [
                    "Error \(code): \(json["error"] ?? "Error")",
                    json["message"] as? String,
                    json["path"].map { "API path: \($0)" }
                ]
                .compactMap { $0 }
                .joined(separator: "\n\n")

                return message
            }

            // Fallback if no data
            switch code {
            case 400: return "Bad Request (400)."
            case 401: return "Unauthorized (401)."
            case 403: return "Forbidden (403)."
            case 404: return "Not Found (404)."
            case 500: return "Server Error (500)."
            default: return "HTTP Error: \(code)."
            }
        case .noBidData(let filename):
            return "Bid Info Data not Available.\n(\(filename))"
        }
    }
}

extension Errors: LocalizedError {
    var errorDescription: String? {
        return self.localizedDescriptionString
    }
}

extension Errors {
    var rawServerMessage: String {
        switch self {
        case .httpStatus(let code, let data):
            if let data = data {
                // Try JSON first
                if let json = try? JSONSerialization.jsonObject(with: data),
                   let dict = json as? [String: Any] {

                    // Join everything into readable text
                    return dict
                        .map { "\($0.key): \($0.value)" }
                        .joined(separator: "\n")
                }

                // Fallback: plain text
                if let text = String(data: data, encoding: .utf8) {
                    return text
                }
            }
            return "Error \(code)"

        case .other(let error):
            return error.localizedDescription

        default:
            return localizedDescription
        }
    }
}

struct AuthResult{
    let isAuthorized: Bool           
    let isSomehowSubscribed: Bool
    let message: String?
    let empName: String
}

class APIService {
    
    static let shared = APIService()
    private init() {}
    
    
    //MARK: Emp Check, Prelogon, Session Cred, Historic bid, Awards, Server log, Bid Submission
    func fetch<T>(
        urlString: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String]? = nil,
        allowNon200Status: Bool = false,
        parse: @escaping (Data) throws -> T,
        completion: @escaping (Result<T, Errors>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error as? URLError, error.code == .timedOut {
                completion(.failure(.timeout))
                return
            }
            if let error = error {
                completion(.failure(.other(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.noData))
                return
            }
            
//            if !allowNon200Status {
//                // Old behavior: Only accept 200–299
//                guard 200..<300 ~= httpResponse.statusCode else {
//                    completion(.failure(.httpStatus(httpResponse.statusCode, data)))
//                    return
//                }
//            }
            if !allowNon200Status, !(200..<300).contains(httpResponse.statusCode) {

                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                    let message = [
                        "Error \(httpResponse.statusCode): \(json["error"] ?? "Error")",
                        json["message"] as? String,
                        "API path: \(json["path"] ?? "")"
                    ]
                    .compactMap { $0 }
                    .joined(separator: "\n\n")

                    let nsError = NSError(
                        domain: "SWA.API",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: message]
                    )

                    completion(.failure(.other(nsError)))
                    return
                }

                completion(.failure(.httpStatus(httpResponse.statusCode, data)))
                return
            }

            if allowNon200Status,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 404 {

                completion(.failure(.httpStatus(404, data)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                let parsed = try parse(data)
                completion(.success(parsed))
            } catch let error as Errors{
                completion(.failure(error))
            }catch{
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    
    
    //MARK: Common Download Function
    func fetchDownload(
            urlString: String,
            httpMethod: HTTPMethod = .POST,
            body: Data? = nil,
            headers: [String: String]? = nil,
            timeout: TimeInterval = 300,
            completion: @escaping (Result<URL, Errors>) -> Void
        ) {
            guard let url = URL(string: urlString) else {
                completion(.failure(.invalidURL))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = httpMethod.rawValue
            request.httpBody = body
            headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = timeout
            config.timeoutIntervalForResource = timeout
            let session = URLSession(configuration: config)

            session.downloadTask(with: request) { tempURL, _, error in
                if let error = error {
                    completion(.failure(.other(error)))
                    return
                }

                guard let tempURL = tempURL else {
                    completion(.failure(.noData))
                    return
                }

                completion(.success(tempURL))
            }.resume()
        }
}

//MARK: Download manager with progress
class DownloadManager: NSObject, URLSessionDataDelegate {
    static let shared = DownloadManager()
    
    var totalProgress: Float = 0
    var totalBytesDownloaded: Float = 0
    private var isPilotDownload: Bool = true
    
    var maxProgress: Float {
        return isPilotDownload ? 0.40 : 0.60
    }
    let estimatedTotalBytes: Float = 400_000
    
    private var expectedContentLength: Int64 = -1
    private var completionHandler: ((Result<URL, Errors>) -> Void)?
    var downloadedData = Data()
    
    func fetch(
        urlString: String,
        httpMethod: HTTPMethod = .POST,
        body: Data? = nil,
        headers: [String: String]? = nil,
        timeout: TimeInterval = 300,
        completion: @escaping (Result<URL, Errors>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        self.downloadedData = Data()
        self.completionHandler = completion

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.httpBody = body
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout

        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }

    // MARK: - URLSessionDataDelegate

    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        expectedContentLength = response.expectedContentLength   // FA gives a real value
        completionHandler(.allow)
    }

    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        
        downloadedData.append(data)
        // Pilot: content length is -1 → use estimated logic
        if dataTask.countOfBytesExpectedToReceive == NSURLSessionTransferSizeUnknown {
            totalBytesDownloaded += Float(data.count)

            let progress = min(totalBytesDownloaded / estimatedTotalBytes * maxProgress, maxProgress)

            NotificationCenter.default.post(
                name: Notification.Name("UpdateProgress"),
                object: nil,
                userInfo: ["progress": progress]
            )
        }
        else {
            // FA: real content length
            let expected = Float(dataTask.countOfBytesExpectedToReceive)
            let received = Float(dataTask.countOfBytesReceived)

            let progress = min(received / expected * maxProgress, maxProgress)

            NotificationCenter.default.post(
                name: Notification.Name("UpdateProgress"),
                object: nil,
                userInfo: ["progress": progress]
            )
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionHandler?(.failure(.other(error)))
            return
        }

        let data = downloadedData

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try data.write(to: tempURL)
            completionHandler?(.success(tempURL))
        } catch {
            completionHandler?(.failure(.other(error)))
        }
    }
}
