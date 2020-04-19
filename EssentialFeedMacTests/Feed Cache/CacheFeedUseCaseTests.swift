//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedMacTests
//
//  Created by Maola Ma on 19/04/2020.
//  Copyright © 2020 Maola. All rights reserved.
//

import XCTest
import EssentialFeedMac

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    typealias FeedResult = ((Error?) -> Void)
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping FeedResult) {
        store.deleteCacheFeed { [weak self] error in
            guard let self = self else { return }
            if(error == nil) {
                self.store.insert(items, timestamp: self.currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletions = (Error?) -> Void
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletions)
    func deleteCacheFeed(completion: @escaping DeletionCompletion)
}


class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages.count, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items) {_ in}
        
        XCTAssertEqual(store.receivedMessages.first, .deleteCacheFeed)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        let deletionError = anyNSError()
        sut.save(items) {_ in}
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items) {_ in}
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(items, timestamp)])
      }
    
    func test_save_failsOnDeleteionError() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let deletionError = anyNSError()

        
        expect(sut, toCompleteWithError: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
     }
    
    func test_save_failsOnInsertionError() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let insertionError = anyNSError()

        expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
        
      }
    
    func test_save_succedsOnSuccessulInsertion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })

        expect(sut, toCompleteWithError: nil, when: {
            store.completeDeletionSuccessfully()
            store.completInsertionSuccessfully()
        })

      }
    
    
    /* Marker: Private helpers */
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryInstance(store)
        trackForMemoryInstance(sut)
        
        return (sut, store)
    }
    
    func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "descr", location: nil, imageURL: URL(string: "any-url")!)
    }
    
    private func anyNSError() -> NSError{
        return  NSError(domain: "Any error", code: 0, userInfo: nil)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError? , when action: () -> Void,  file: StaticString = #file, line: UInt = #line ) {
        let exp = expectation(description: "Wait for save to complete")
        let items = [uniqueItem(), uniqueItem()]

        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }
    
    
    
    private class FeedStoreSpy: FeedStore {
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletions = (Error?) -> Void

        private var insertionCompletions = [InsertionCompletions]()
        private var deletionCompletions = [DeletionCompletion]()
        private(set) var receivedMessages = [ReceivedMessage]()
        
        enum ReceivedMessage: Equatable {
            case deleteCacheFeed
            case insert([FeedItem], Date)
        }
            
        func deleteCacheFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCacheFeed)
        }
        
        func completeDeletion(with error: NSError, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletions) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(items, timestamp))
        }
        
        func completeInsertion(with error: NSError, at index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}
