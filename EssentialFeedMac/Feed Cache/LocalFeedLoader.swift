//
//  LocalFeedLoader.swift
//  EssentialFeedMac
//
//  Created by Maola Ma on 26/04/2020.
//  Copyright © 2020 Maola. All rights reserved.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    public typealias FeedResult = ((Error?) -> Void)
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping FeedResult) {
        store.deleteCacheFeed { [weak self] deletionError in
            guard let self = self else { return }

            if let deletionError = deletionError {
                completion(deletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
    
    
    private func cache(_ items: [FeedItem], with completion: @escaping (Error?) -> Void) {
        store.insert(items, timestamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletions = (Error?) -> Void
    
    func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletions)
    func deleteCacheFeed(completion: @escaping DeletionCompletion)
}
