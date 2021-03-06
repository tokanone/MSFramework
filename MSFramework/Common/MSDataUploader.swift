//
//  MSDataUploader.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/25/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

///The data uploader class
///
///MSDataUploader connects to a `URL`, sends a `POST` request containing the SQL statement to run, downloads **Success** or **Failure**, and returns a Bool based upon that
public final class MSDataUploader: NSObject, URLSessionDelegate
{
    private lazy var uploadSession : URLSession = {
        return URLSession(configuration: MSFrameworkManager.default.defaultSession, delegate: self, delegateQueue: nil)
    }()
    
    override init() { }
    
    public func createNewUser(from sqlStatement: MSSQL, email: String, completion: ((String?) -> Void)? = nil)
    {
        if MSFrameworkManager.debug { print(sqlStatement.formattedStatement) }
        guard let dataSource = MSFrameworkManager.default.dataSource else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let url = URL(string: dataSource.website)!.appendingPathComponent(dataSource.createUserFile)
        
        let postString = "Password=\(dataSource.databaseUserPass)&Username=\(dataSource.websiteUserName)&Email=\(email)&SQLQuery=\(sqlStatement.formattedStatement.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")"
        if MSFrameworkManager.debug { print(postString) }
        let postData = postString.data(using: .utf8, allowLossyConversion: true)
        let postLength = String(postData!.count)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpBody = postData
        
        uploadSession.dataTask(with: request, completionHandler: { returnData, response, error in
            DispatchQueue.main.async {
                if let error = error
                {
                    print(error)
                    completion?(nil)
                    return
                }
                if MSFrameworkManager.debug { print("Response: \(String(describing: response))") }
                guard response?.url?.absoluteString.hasPrefix(dataSource.website) == true, let returnData = returnData, let stringData = String(data: returnData, encoding: .utf8) else
                {
                    completion?(nil)
                    return
                }
                if MSFrameworkManager.debug { print("Return Data: \(stringData)") }
                if stringData.contains("Failure")
                {
                    completion?(nil)
                }
                else
                {
                    completion?(stringData)
                }
            }
        }).resume()
    }
    
    public func upload(customPOSTQueries: [String: String], completion: MSFrameworkUploadCompletion? = nil)
    {
        guard let dataSource =  MSFrameworkManager.default.dataSource else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let url = URL(string: dataSource.website)!.appendingPathComponent(dataSource.customKeyValuesFile)
        
        var customParameters = ""
        for (key, value) in customPOSTQueries
        {
            customParameters += "\(key)=\(value)&"
        }
        customParameters = String(customParameters[customParameters.startIndex..<customParameters.index(before: customParameters.endIndex)])
        
        let postString = customParameters
        if MSFrameworkManager.debug { print(postString) }
        let postData = postString.data(using: .utf8, allowLossyConversion: true)
        let postLength = String(postData!.count)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpBody = postData
        
        uploadSession.dataTask(with: request, completionHandler: { returnData, response, error in
            DispatchQueue.main.async {
                if let error = error
                {
                    print(error)
                    completion?(false)
                    return
                }
                if MSFrameworkManager.debug { print("Response: \(String(describing: response))") }
                guard response?.url?.absoluteString.hasPrefix(dataSource.website) == true else
                {
                    completion?(false)
                    return
                }
                completion?(true)
            }
        }).resume()
    }
    
    /**
     Uploads an SQL statement to `website`+`writeFile`.
     
     This method will return control to your application immediately, deferring call back to `completion`.  `completion` will always be ran on the main thread
     
     - Parameter sqlStatement: A valid MSSQL object
     - Parameter completion: A block to be called when `website`+`writeFile` has returned either **Success** or **Failure**
     */
    public func upload(sqlStatement: MSSQL, completion: MSFrameworkUploadCompletion? = nil)
    {
        if MSFrameworkManager.debug { print(sqlStatement.formattedStatement) }
        guard let dataSource =  MSFrameworkManager.default.dataSource else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let url = URL(string: dataSource.website)!.appendingPathComponent(dataSource.writeFile)
        
        let postString = "Password=\(dataSource.databaseUserPass)&Username=\(dataSource.websiteUserName)&SQLQuery=\(sqlStatement.formattedStatement.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? "")"
        if MSFrameworkManager.debug { print(postString) }
        let postData = postString.data(using: .utf8, allowLossyConversion: true)
        let postLength = String(postData!.count)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpBody = postData
        
        uploadSession.dataTask(with: request, completionHandler: { returnData, response, error in
            DispatchQueue.main.async {
                if let error = error
                {
                    print(error)
                    completion?(false)
                    return
                }
                if MSFrameworkManager.debug { print("Response: \(String(describing: response))") }
                guard response?.url?.absoluteString.hasPrefix(dataSource.website) == true, let returnData = returnData, let stringData = String(data: returnData, encoding: .utf8) else
                {
                    completion?(false)
                    return
                }
                if MSFrameworkManager.debug { print("Return Data: \(stringData)") }
                completion?(stringData.contains("Success"))
            }
        }).resume()
    }
    
    //MARK: NSURLSessionDelegate
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        guard let dataSource =  MSFrameworkManager.default.dataSource else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let credential = URLCredential(user: dataSource.websiteUserName, password: dataSource.websiteUserPass, persistence: .forSession)
        completionHandler(.useCredential, credential)
    }
}
