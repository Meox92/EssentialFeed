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

        expect(sut, toCompleteWith: .failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0, userInfo: nil)
            client.complete(with: clientError)
        })
    }
    
    
    func test_load_deliversErrorOnNot200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        [199, 201, 300, 400, 500].enumerated().forEach { index,statusCode in
            var capturedError = [RemoteFeedLoader.Result]()
            // When
            sut.load() { err in
                capturedError.append(err)
            }
            let jsonData = makeItemsJSON([])
            client.complete(withStatusCode: statusCode, data: jsonData, at: index)
            
            // Then
            XCTAssertEqual(capturedError, [.failure(.invalidData)])
        }
    }
    
    
    func test_load_deliversErrorOn200HTTPResposeWithInvalidJSON(){
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJsonList() {
        let (sut, client) = makeSUT()
                
        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJson = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJson)
        })
    }
    
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()

        let item1  = makeItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
        let item2 = makeItem(id: UUID(), description: "descr", location: "prato", imageURL: URL(string: "http://another-url.com")!)
        

        expect(sut, toCompleteWith: .success([item1.model, item2.model]), when: {
            let itemJSON = [item1.json, item2.json]
            client.complete(withStatusCode: 200, data: makeItemsJSON(itemJSON))
        })
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
        
        func complete(withStatusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: withStatusCode,
                                           httpVersion: nil,
                                           headerFields: nil
            )
            messages[index].completion(.success(data, response!))
        }
    }
}

extension RemoteFeedLoaderTests {
    // Private helpers
    private func makeSUT(with url: URL? = URL(string: "http://url-di-default")) -> (sut: RemoteFeedLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        return (RemoteFeedLoader(url: url!, client: client), client)
    }
    
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) ->(model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
            ].reduce(into:[String: Any]()) { (acc, e) in
                if let value = e.value {acc[e.key] = value }
            }
        return (item, json)
    }
    
    private func makeItemsJSON (_ items: [[String: Any]]) -> Data {
        let itemsJSON = [
            "items": items]
        let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
        return json
        
    }
    
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        // When
        sut.load() { err in
            capturedResults.append(err)
        }
        
        action()
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
        
        
    }
}


// https://academy.essentialdeveloper.com/courses/447455/lectures/8732933 27.36
