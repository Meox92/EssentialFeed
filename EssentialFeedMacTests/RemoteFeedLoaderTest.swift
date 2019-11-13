//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedMacTests
//
//  Created by Maola Ma on 13/11/2019.
//  Copyright © 2019 Maola. All rights reserved.
//

import XCTest

class RemoteFeedLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}

class RemoteFeedLoaderTest: XCTest {
    func test_init_doesNotRequestData() {
        let client = HTTPClient()
        let sut = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
        
    }
}
