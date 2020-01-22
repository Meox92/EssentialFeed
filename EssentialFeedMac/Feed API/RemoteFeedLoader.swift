//
//  RemoteFeedLoader.swift
//  EssentialFeedMac
//
//  Created by Maola Ma on 03/12/2019.
//  Copyright © 2019 Maola. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
    case success(HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}


public final class RemoteFeedLoader {
    private var client: HTTPClient
    private var url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: self.url) { result in
            switch result {
            case .failure(let error):
                completion(.connectivity)
            case .success(let response):
                completion(.invalidData)
            }
        }
    }
}

