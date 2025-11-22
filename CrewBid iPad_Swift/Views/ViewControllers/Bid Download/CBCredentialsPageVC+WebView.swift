//
//  CBCredentialsPageVC+WebView.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 14/11/25.
//

import UIKit
import WebKit

extension CBCredentialsPageVC: WKNavigationDelegate{
    
    func startAuthFlow(){
        if let url = createAuthURL(){
            webView.navigationDelegate = self
            webView.load(URLRequest(url: url))
        }
    }
    
    private func createAuthURL() -> URL?{
        codeVerifier = generateCodeVerifier()
        guard let codeChallenge = generateCodeChallenge(from: codeVerifier) else {return nil}
        
        var components = URLComponents(string: authorizationEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "prompt", value: "login"),
            URLQueryItem(name: "scope", value: "openid email profile address phone")
        ]
        return components?.url
    }
    
    private func generateCodeVerifier() -> String{
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<128).compactMap { _ in characters.randomElement() })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        let hashData = Data(hash)
        let base64String = hashData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return base64String
    }
    
    func stopWebViewOperations(){
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        print("Stopped WebView operations.")
    }
    
    private func exchangeCodeForToken(authCode: String) {
        webViewloaded = true
        let urlString = tokenEndpoint
        let grantType = "grant_type=authorization_code"
        let codeParam = "&code=\(authCode)"
        let redirectURIParam = "&redirect_uri=\(self.redirectURI)"
        let clientIDParam = "&client_id=\(self.clientID)"
        let codeVerifierParam = "&code_verifier=\(self.codeVerifier)"
        let audience1 = "&aud=aud://sso.fed.\(env).aws.swacorp.com/cbna/p502553"
        let audience2 = "&aud=aud://sso.fed.\(env).aws.swacorp.com/cbna/p502552"
        let audience3 = "&aud=aud://sso.fed.\(env).aws.swacorp.com/cbna/p502554"
        
        let body = "\(grantType)\(codeParam)\(redirectURIParam)\(clientIDParam)\(codeVerifierParam)\(audience1)\(audience2)\(audience3)"
        let bodyData = body.data(using: .utf8)
        
        APIService.shared.fetch(
            urlString: urlString,
            method: .POST,
            body: bodyData,
            headers: ["Content-Type":"application/x-www-form-urlencoded"],
            parse: { data in
                let jsonResponse = try JSONSerialization.jsonObject(with: data) as! [String:Any]
                return jsonResponse
            },
            completion: { result in
                switch result{
                case .success(let response):
                    let token = response["access_token"] as! String
                    self.saveToKeychain(token: token)
                    
                case .failure(let error):
                    AlertService.showAlertForTopVC(title: "Authentication Failed", message: error.localizedDescription)
                    print("Error: \(error.localizedDescription)")
                }
            })
    }
    
    private func saveToKeychain(token: String){
        let userDetail = JWTDecoder.decode(jwtToken: token)!
        
        let group = userDetail["groups"] as! String
        
        if !group.contains("Attendant"){
            AlertService.showAlertForTopVC(title: "Authentication Failed", message: "You are attempting to log in with Pilot credentials. Please use valid Flight Attendant credentials instead.")
            return
        }
        
        let tokenData = token.data(using: .utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "BearerToken"
        ]
        
        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound {
            print("Keychain item deleted (or not found). Proceeding to add the new token.")
        } else {
            print("Failed to delete Keychain item, error code: \(deleteStatus)")
            return
        }
        // Add the new token
        var addQuery = query
        addQuery[kSecValueData as String] = tokenData

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            print("Token saved successfully!")
            
            DispatchQueue.main.async {
                self.stopWebViewOperations()
                
                let token = KeychainHelper.retrieveTokenFromKeyChain()
                let userDetails = JWTDecoder.decode(jwtToken: token!)
                let rawUserId = (userDetails?["cn"] as? String) ?? ""

                let normalizedId = rawUserId.lowercased().hasPrefix("e") || rawUserId.lowercased().hasPrefix("x")
                    ? String(rawUserId.dropFirst())
                    : rawUserId

                self.userid = normalizedId
                
                
                self.webViewModel?.onDownloadError = { [weak self] error in
                    self?.handleDownloadError(error)
                }
                self.checkAuthenticationFA()
            }
        }
    }
    
    func handleDownloadError(_ error: NSError) {
        if isAllDomicelEnabled() {
            var parameters: [String: Any] = [:]
            parameters["errorInfo"] = error.localizedDescription
            NotificationCenter.default.post(
                name: Notification.Name("BidDownloadError"),
                object: parameters
            )
        } else {
            let attrString = AlertService.getAttributedMessage(from: error.localizedDescription, highlight: "Bid Download Error")
            DispatchQueue.main.async {
                AlertService.showDBAlert(title: "Bid Download Error!", attributedMessage: attrString, from: self)
            }
        }
    }
    
    func isAllDomicelEnabled() -> Bool {
        if let secretDownloadAllDomicileEnabled = UserDefaults.standard.string(forKey: "isSecretForAllDomicileDownloadEnabled") {
            return secretDownloadAllDomicileEnabled == "YES"
        }
        return false
    }
    
    func checkAuthenticationFA(){

        if app.connectedToInternet(){
            switch app.objNetworkType {
            case .ground:
                self.checkAuthentication()
                break
            case .free:
                
                break
            case .paid:
                self.checkAuthentication()
                break
            }
        }
    }
    
    func startBidDownload(){
        self.view.hideActivityIndicator()
        NotificationCenter.default.post(name: Notification.Name("ShowProgressView"), object: nil)
        self.webViewModel?.startBidInfoDownload(){ result in
            DispatchQueue.main.async {
                switch result{
                case .success(()):
                    print("Historic Bid download complete — navigating")
                    self.loginActions()
                case .failure(let error):
                    print("Historic bid download failed: \(error.localizedDescription)")
                    AlertService.showAlertForTopVC(title: "Error", message: "Failed to download bid data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.absoluteString.contains("code="),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                let queryItems = components.queryItems ?? []
                if let authCode = queryItems.first(where: { $0.name == "code" })?.value {
                    exchangeCodeForToken(authCode: authCode)
                    decisionHandler(.cancel)
                    return
                }
            }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        backBtn.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webViewloaded = true
        backBtn.isHidden = false

        let js = """
        (function() {
            var errorEl = document.querySelector('.ping-error');
            var usernameEl = document.querySelector('#username');
            var errorMsg = errorEl ? errorEl.textContent.trim() : null;
            var usernameVal = usernameEl ? usernameEl.value : null;
            return { error: errorMsg, username: usernameVal };
        })();
        """
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                print("JavaScript evaluation error: \(error)")
                return
            }

            if let dict = result as? [String: Any] {

//                self.logFailedAuthenticationDetails(dict)
                
            } else if result != nil {
                print("JS result: \(String(describing: result))")
            } else {
                print("No result returned from JS")
            }
        }
        self.view.hideActivityIndicator()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.webViewloaded = true
        self.view.hideActivityIndicator()
        backBtn.isHidden = false

    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.webViewloaded = true
        self.view.hideActivityIndicator()
        backBtn.isHidden = false

    }
    
}
