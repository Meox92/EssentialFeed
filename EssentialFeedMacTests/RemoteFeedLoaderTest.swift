//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedMacTests
//
//  Created by Maola Ma on 13/11/2019.
//  Copyright © 2019 Maola. All rights reserved.
//

import XCTest

class RemoteFeedLoader {
    var client: HTTPClient
    var url: URL
    
    init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    func load() {
        client.get(from: self.url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}



class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestData() {
        let (_, client) = makeSUT()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let (sut, client) = makeSUT()
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
        XCTAssertEqual(client.requestedURL, sut.url)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?

        func get(from url: URL) {
          requestedURL = url
        }
    }
}

extension RemoteFeedLoaderTests {
    // Private helpers
    private func makeSUT() -> (sut: RemoteFeedLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        let url = URL(string: "http://url-a-caso")
        return (RemoteFeedLoader(url: url!, client: client), client)
    }
}
