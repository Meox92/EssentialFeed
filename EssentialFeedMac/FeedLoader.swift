//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Maola Ma on 13/11/2019.
//  Copyright © 2019 Maola. All rights reserved.
//

import Foundation
enum FeedLoadResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping(FeedLoadResult) -> Void)
}
