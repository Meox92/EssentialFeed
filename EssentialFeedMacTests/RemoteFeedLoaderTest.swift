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
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "http://url-a-caso")
        let (sut, client) = makeSUT(with: url)
        
        sut.load() { _ in }
        
        XCTAssertNotNil(client.requestedURLs)
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_deliversErrorOnClient() {
        let (sut, client) = makeSUT()
        var capturedError = [RemoteFeedLoader.Error]()
        // When
        sut.load() { err in
            capturedError.append(err)
        }
        let clientError = NSError(domain: "Test", code: 0, userInfo: nil)
        client.complete(with: clientError)
        // Then
        XCTAssertEqual(capturedError, [.connectivity])
    }
    
    
    func test_load_deliversErrorOnNot200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        [199, 201, 300, 400, 500].enumerated().forEach { index,statusCode in
            var capturedError = [RemoteFeedLoader.Error]()
            // When
            sut.load() { err in
                capturedError.append(err)
            }
            
            client.complete(withStatusCode: statusCode, at: index)
            
            // Then
            XCTAssertEqual(capturedError, [.invalidData])
        }
    }
    
    
    
    
    
    
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedURLs: [URL] {
            return messages.map( {$0.url})
        }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: withStatusCode,
                                           httpVersion: nil,
                                           headerFields: nil
            )
            messages[index].completion(.success(response!))
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


// https://academy.essentialdeveloper.com/courses/447455/lectures/8575843 8.27
