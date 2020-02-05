//
//  HTTPClient.swift
//  EssentialFeedMac
//
//  Created by Maola Ma on 28/01/2020.
//  Copyright © 2020 Maola. All rights reserved.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
