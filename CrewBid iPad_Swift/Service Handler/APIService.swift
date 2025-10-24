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
    case emptyData
    case networkError
    case other(Error)
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
        }
    }
}

extension Errors: LocalizedError {
    var errorDescription: String? {
        return self.localizedDescriptionString
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
            guard
                let httpResponse = response as? HTTPURLResponse,
                200..<300 ~= httpResponse.statusCode,
                let data = data
            else {
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
    private var completionHandler: ((Result<URL, Errors>) -> Void)?
    private var tempFileURL: URL?
    var downloadedData = Data()
    
    var totalProgress: Float = 0
    var totalBytesDownloaded: Float = 0
    let maxProgress: Float = 0.40
    let estimatedTotalBytes: Float = 4_00_000
    
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

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        downloadedData.append(data)
        totalBytesDownloaded += Float(data.count)

        let progress = min(totalBytesDownloaded / estimatedTotalBytes * maxProgress, maxProgress)
        totalProgress = progress
        NotificationCenter.default.post(
               name: Notification.Name("UpdateProgress"),
               object: nil,
               userInfo: ["progress": totalProgress]
           )
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
