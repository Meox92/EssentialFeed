//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Maola Ma on 13/11/2019.
//  Copyright © 2019 Maola. All rights reserved.
//

import Foundation

public struct FeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(id: UUID, description: String?, location: String?, imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}

