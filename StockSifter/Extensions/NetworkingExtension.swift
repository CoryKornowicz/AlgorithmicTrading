//
//  NetworkingExtension.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 7/20/18.
//  Copyright © 2018 Cory Kornowicz. All rights reserved.
//

import Foundation

enum URLResult {
    case response(Data, URLResponse)
    case error(Error, Data?, URLResponse?)
}

extension URLSession {
    @discardableResult
    func get(_ url: URL, completionHandler: @escaping (URLResult) -> Void) -> URLSessionDataTask {
        let task = dataTask(with: url) { data, response, error in
            switch (data, response, error) {
            case let (data, response, error?):
                completionHandler(.error(error, data, response))
            case let (data?, response?, nil):
                completionHandler(.response(data, response))
            default:
                preconditionFailure("expected either Data and URLResponse, or Error")
            }
        }
        task.resume()
        return task
    }
    
    func get(_ urls: [URL], completionHandler: @escaping ([URLResult]) -> Void){
        
        var urlResults: [URLResult] = []
        
        if (urls.isEmpty){
            completionHandler(urlResults)
        }
        
        func continuation(){
            if urlResults.count == urls.count {
                completionHandler(urlResults)
            }else {
                return
            }
        }
        
        urls.forEach { (url) in
            get(url, completionHandler: { (result) in
                urlResults.append(result)
                continuation()
            })
        }
    
    }
    
}

extension URLResult {
    var string: String? {
        guard case let .response(data, _) = self,
            let string = String(data: data, encoding: .utf8)
            else { return nil }
        return string
    }
}
