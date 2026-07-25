//
//  Coding.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 7/14/26.
//

import Foundation

public extension JSONEncoder {
    static let trailmark: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}


public extension JSONDecoder{
    static let trailmark: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
