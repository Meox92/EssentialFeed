//
//  XCTestCase+MemoryLeaksTracking.swift
//  EssentialFeedMacTests
//
//  Created by Maola Ma on 11/02/2020.
//  Copyright © 2020 Maola. All rights reserved.
//

import XCTest

extension XCTestCase {
    func trackForMemoryInstance(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Potential memory leak", file: file, line: line)
        }
    }
}
