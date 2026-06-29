//
//  MediaMemo.swift
//  TrailMarkCore
//
//  Created by Kit Sitou on 6/27/26.
//

import Foundation
import CoreLocation

public enum MemoKind: String, Codable, Sendable, CaseIterable{
    case audio
    case video
    
    public var symbolName: String{
        switch self{
        case .audio: return "waveform"
        case .video: return "video.fill"
        }
    }
    
    public var displayName: String{
        switch self{
        case .audio: return "Voice Memo"
        case .video: return "Video Memo"
        }
    }
}



public struct MediaMemo: Identifiable, Hashable, Sendable, Codable{
    public let id: UUID
    public var kind: MemoKind
    //filename relative to the media directory
    public var fileName: String
    public var createdAt: Date
    public var duration: TimeInterval //00:00:00
    public var title: String
    
    public init(
        id: UUID = UUID(),
        kind: MemoKind,
        fileName: String,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        title: String = ""
    ){
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
        self.title = title.isEmpty ? Self.defaultTitle(for: kind, date: createdAt) : title //Self upperCase becuase calling static func
    }
    
    public var durationText:String{
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
    
    //when title is not specified this function will create a default title like audto memo - 06/07/2026 9:39 am
    //static class does not need init
    private static func defaultTitle(for kind: MemoKind, date: Date) -> String{
        //Dates follow ISO6001 2026*0627T
        let df = DateFormatter()
        df.dateStyle = .medium //Apr,26,2026
        df.timeStyle = .short //9:39am
        
        return "\(kind.displayName)-\(df.string(from: date))"
    }
    
}
