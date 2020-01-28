//
//  RemoteFeedLoader.swift
//  EssentialFeedMac
//
//  Created by Maola Ma on 03/12/2019.
//  Copyright © 2019 Maola. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
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
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (RemoteFeedLoader.Result) -> Void) {
        client.get(from: self.url) { result in
            switch result {
            case .failure:
                completion(.failure(.connectivity))
            case let .success(data, response):
                if let items = try? FeedItemsMapper.map(data, response) {
                     completion(.success(items))
                } else {
                    completion(.failure(.invalidData))
                }
                

            }
        }
    }
    
    
    
    
}

private class FeedItemsMapper {
    
    private struct Root: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            return FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }

    
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return try JSONDecoder().decode(Root.self, from: data).items.map {$0.item}
    }
}




