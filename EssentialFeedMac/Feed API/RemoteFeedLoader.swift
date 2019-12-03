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
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load() {
        client.get(from: self.url)
    }
}

public protocol HTTPClient {
    func get(from url: URL)
}
