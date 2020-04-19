//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedMacTests
//
//  Created by Maola Ma on 13/11/2019.
//  Copyright © 2019 Maola. All rights reserved.
//

import XCTest
import EssentialFeedMac

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    
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

        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0, userInfo: nil)
            client.complete(with: clientError)
        })
    }
    
    
    func test_load_deliversErrorOnNot200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        [199, 201, 300, 400, 500].enumerated().forEach { index,statusCode in
            let expectedResult = RemoteFeedLoader.Result.failure(RemoteFeedLoader.Error.invalidData)
            let exp = expectation(description: "Wait fo complete")
            // When
            sut.load() { receivedResult in
                switch (receivedResult, expectedResult) {
                   case let (.failure(receivedError), .failure(expectedError)):
                    XCTAssertEqual(receivedError as! RemoteFeedLoader.Error, expectedError as! RemoteFeedLoader.Error)
                   default:
                    XCTFail("Expecte result \(expectedResult), but got \(receivedResult) instead")
                }
                exp.fulfill()
            }
            
            let jsonData = makeItemsJSON([])
            client.complete(withStatusCode: statusCode, data: jsonData, at: index)
            wait(for: [exp], timeout: 5.0)
        }
    }
    
    
    func test_load_deliversErrorOn200HTTPResposeWithInvalidJSON(){
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: failure(.invalidData), when: {
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
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://a-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load() { err in
            capturedResults.append(err)
        }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
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

extension LoadFeedFromRemoteUseCaseTests {
    // Private helpers
    private func makeSUT(with url: URL? = URL(string: "http://url-di-default"), file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url!, client: client)
        
        trackForMemoryInstance(client)
        trackForMemoryInstance(sut)
        
        return (sut, client)
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
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
    
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "Waif for load completion")
        
        // When
        sut.load() { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedResult),.success(expectedResult)):
                XCTAssertEqual(receivedResult, expectedResult, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expecte result \(expectedResult), but got \(receivedResult) instead", file: file, line: line)

            }
            
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 5.0)
        
    }
}


// https://academy.essentialdeveloper.com/courses/447455/lectures/8732933 27.36
