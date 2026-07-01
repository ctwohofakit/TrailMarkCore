//
//  MediaStore.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 6/27/26.
//

import Foundation
import Combine
import AVFoundation
import CoreLocation
import Observation

#if canImport(UIKit)
import UIKit
#endif


@MainActor
@Observable
// final prevents other classes from inheriting from it, can't extend it
public final class MediaStore{
    public private(set) var memos: [MediaMemo] = []
    
    private let fileManager = FileManager.default
    //index is where the app storage is
    private let indexFileName = "memos.json"
    
    
    public init() {
        loadIndex()
    }

    public var mediaDirectory: URL{
        //in for user domain mask for security
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Media", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path){
            try? fileManager.createDirectory(atPath: dir.path, withIntermediateDirectories: true)
        }
        return dir
    }
    
    //first line i the deafault return statement
    private var indexURL: URL {
        mediaDirectory.appendingPathComponent(indexFileName)
    }
    
    public func url(for memo: MediaMemo)-> URL{
        mediaDirectory.appendingPathComponent(memo.fileName)
    }
    
    @discardableResult
    public func add(
        kind: MemoKind,
        movingFileFrom sourceURL: URL,
        duration: TimeInterval,
        title: String = "",
    )throws -> MediaMemo{
        let id = UUID()
        let ext = sourceURL.pathExtension.isEmpty ? (kind == .audio ? "m4a" : "mov") : sourceURL.pathExtension
        let fileName = "\(id.uuidString).\(ext)"
        let destination = mediaDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: destination.path){
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: sourceURL, to: destination)
        
        var memo = MediaMemo(
            id: id,
            kind: kind,
            fileName: fileName,
            duration: duration,
            title: title
        )
        
        memos.insert(memo, at:0)
        persistIndex()
        return memo
    }
    
    private func persistIndex(){
        guard let data = try? JSONEncoder().encode(memos) else {return}
        try? data.write(to: indexURL, options: .atomic)
        
    }
    private func loadIndex(){
        guard let data = try? Data(contentsOf: indexURL) else {return}
        let decoded = (try? JSONDecoder().decode([MediaMemo].self, from: data)) ?? []
        memos = decoded.sorted{ $0.createdAt > $1.createdAt}
        
    }
}
