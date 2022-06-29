//
//  MatchingMusic.swift
//  ShazamTest
//
//  Created by 이주화 on 2022/06/20.
//

import AVFAudio
import Foundation
import ShazamKit

class MatchingMusic: NSObject {
  private var session: SHSession?
  private let audioEngine = AVAudioEngine()

  private var matchHandler: ((SHMatchedMediaItem?, Error?) -> Void)?
  typealias MatchWithContentHandler = ((SHMatchedMediaItem?, VideoAnnotation?, Error?) -> Void)
  private var matchWithContentHandler: MatchWithContentHandler?

  private var lastMatch: SHMatchedMediaItem?
  private var lastAnnotationMatch: VideoAnnotation?

  init(matchHandler handler: ((SHMatchedMediaItem?, Error?) -> Void)?) {
    matchHandler = handler
  }

  init(matchWithContentHandler handler: MatchWithContentHandler?) {
    matchWithContentHandler = handler
  }

  func match(catalog: SHCustomCatalog? = nil) throws {
    if let catalog = catalog {
      session = SHSession(catalog: catalog)
    } else {
      session = SHSession()
    }

    session?.delegate = self

    let audioFormat = AVAudioFormat(
      standardFormatWithSampleRate: audioEngine.inputNode.outputFormat(forBus: 0).sampleRate,
      channels: 1)
    audioEngine.inputNode.installTap(
      onBus: 0,
      bufferSize: 2048,
      format: audioFormat
    ) { [weak session] buffer, audioTime in
      session?.matchStreamingBuffer(buffer, at: audioTime)
    }

    try AVAudioSession.sharedInstance().setCategory(.record)
    AVAudioSession.sharedInstance().requestRecordPermission { [weak self] success in
      guard
        success,
        let self = self
      else { return }
      try? self.audioEngine.start()
    }
  }

  func stopListening() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
  }
}

extension MatchingMusic: SHSessionDelegate {
  func session(_ session: SHSession, didFind match: SHMatch) {
    DispatchQueue.main.async { [weak self] in
    guard let self = self else {
      return
    }

      if let handler = self.matchHandler {
        handler(match.mediaItems.first, nil)
        self.stopListening()
      }

      if let handler = self.matchWithContentHandler {
        let matchedAnnotation = VideoAnnotation.sampleAnnotations.last { annotation in
          (match.mediaItems.first?.predictedCurrentMatchOffset ?? 0) > annotation.offset
        }

        if match.mediaItems.first != self.lastMatch || matchedAnnotation != self.lastAnnotationMatch {
          handler(match.mediaItems.first, matchedAnnotation, nil)
          self.lastMatch = match.mediaItems.first
          self.lastAnnotationMatch = matchedAnnotation
        }
      }
    }
  }

  func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
    print("Did not find match for \(signature) | Error: \(String(describing: error))")
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }

      if let handler = self.matchHandler {
        handler(nil, error)
        self.stopListening()
      }

      if let handler = self.matchWithContentHandler {
        handler(nil, nil, error)
        self.stopListening()
      }
    }
  }
}

struct VideoAnnotation: Comparable, Equatable {
  let content: String
  let imageName: String?
  let offset: TimeInterval

  init(content: String, offset: TimeInterval, imageName: String? = nil) {
    self.content = content
    self.offset = offset
    self.imageName = imageName
  }

  static func < (lhs: VideoAnnotation, rhs: VideoAnnotation) -> Bool {
    return lhs.offset < rhs.offset
  }

  static func == (lhs: VideoAnnotation, rhs: VideoAnnotation) -> Bool {
    return lhs.content == rhs.content && lhs.offset == rhs.offset
  }
}

extension VideoAnnotation {
  static let sampleAnnotations = [
    VideoAnnotation(content: "Welcome!", offset: 5, imageName: "an-1"),
    VideoAnnotation(content: "Your first SwiftUI app!", offset: 14, imageName: "an-2"),
    VideoAnnotation(content: "Your first SwiftUI app! \nBulls Eye", offset: 14, imageName: "an-2"),
    VideoAnnotation(content: "😉", offset: 45, imageName: "an-1"),
    VideoAnnotation(content: "Course Overview: \nSwiftUI vs UIKit", offset: 47, imageName: "an-overview"),
    VideoAnnotation(content: "Should you learn SwiftUI? UIKit? or Both? 🤔", offset: 57, imageName: "an-1"),
    VideoAnnotation(content: "Course Overview: \nGetting Started with SwiftUI", offset: 76, imageName: "an-overview"),
    VideoAnnotation(content: "Course Overview: \nSwiftUI View Modifiers", offset: 85, imageName: "an-overview"),
    VideoAnnotation(content: "Course Overview: \nButtons and Actions", offset: 93, imageName: "an-overview"),
    VideoAnnotation(content: "Course Overview: \nSwiftUI State", offset: 100, imageName: "an-overview"),
    VideoAnnotation(content: "Course Overview: \nSwift Language Basics", offset: 106, imageName: "an-overview"),
    VideoAnnotation(content: "Course Overview: \nUnit Testing and TDD", offset: 120, imageName: "an-overview"),
    VideoAnnotation(content: "Open Xcode and follow along!", offset: 127, imageName: "an-3"),
    VideoAnnotation(content: "The only way to learn programming is to actually do it", offset: 160, imageName: "an-4"),
    VideoAnnotation(content: "Put in the time and the work! 😎", offset: 173, imageName: "an-5"),
    VideoAnnotation(content: "Download the latest version of Xcode", offset: 183, imageName: "an-6"),
    VideoAnnotation(content: "Let's get started!", offset: 195, imageName: "an-7")
  ]
}
