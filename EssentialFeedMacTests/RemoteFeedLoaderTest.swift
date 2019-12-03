//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedMacTests
//
//  Created by Maola Ma on 13/11/2019.
//  Copyright © 2019 Maola. All rights reserved.
//

import XCTest
import EssentialFeedMac

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestData() {
        let (_, client) = makeSUT()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "http://url-a-caso")
        let (sut, client) = makeSUT(with: url)
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
        XCTAssertEqual(client.requestedURL, url)
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
    private func makeSUT(with url: URL? = URL(string: "http://url-di-default")) -> (sut: RemoteFeedLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        return (RemoteFeedLoader(url: url!, client: client), client)
    }
}
