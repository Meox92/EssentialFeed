//
//  RemoteFeedLoader.swift
//  EssentialFeedMac
//
//  Created by Maola Ma on 03/12/2019.
//  Copyright © 2019 Maola. All rights reserved.
//

import Foundation


public final class RemoteFeedLoader {
    private var client: HTTPClient
    private var url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (RemoteFeedLoader.Result) -> Void) {
        client.get(from: self.url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                completion(.failure(.connectivity))
            case let .success(data, response):
                let result = FeedItemsMapper.map(data, from: response) // map è una funziona statica, quindi verrà invocata anche quando l'istanza di RemoteFeedLoader viene deallocata
                completion(result)
            }
        }
    }
    


}




