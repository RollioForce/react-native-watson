//
//  Created by Patrick cremin on 8/2/17.
//

import Foundation
import SpeechToText
import AVFoundation
import RestKit


// SpeechToText
@objc(RNSpeechToText)
class RNSpeechToText: RCTEventEmitter {

  var accumulator = SpeechRecognitionResultsAccumulator()
  var speechToText: SpeechToText?
  var audioPlayer = AVAudioPlayer()
  var callback: RCTResponseSenderBlock?
  var hasListeners = false
  var isListening = false;

  static let sharedInstance = RNSpeechToText()

  private override init() {}

  override func supportedEvents() -> [String]! {
    return ["StreamingText"]
  }

  @objc func initialize(_ apiKey: String) -> Void {
    do {
      let audioSession = AVAudioSession.sharedInstance();

      try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
    } catch {
      print(error)
    }

    speechToText = SpeechToText(apiKey: apiKey)
    speechToText?.defaultHeaders = ["X-Watson-Learning-Opt-Out": "true"]
  }

  @objc func startStreaming(_ languageCustomizationID: String?, errorCallback: @escaping RCTResponseSenderBlock) {
    self.isListening = true
    self.accumulator = SpeechRecognitionResultsAccumulator()
    
    var settings = RecognitionSettings(contentType: "audio/ogg")
    settings.interimResults = true
    settings.smartFormatting = true

    var callback = RecognizeCallback()

    callback.onResults = { payload in
      if(self.hasListeners)
      {
        self.accumulator.add(results: payload)
        let isFinal = payload.results?.last?.finalResults ?? true

        self.sendEvent(withName: "StreamingText", body: [
          "text": self.accumulator.bestTranscript,
          "isFinal": isFinal,
          "isListening": self.isListening
        ])
      }
    }

    callback.onError = { (error: Error) in
      errorCallback([error])
      self.isListening = false
    }

    speechToText?.recognizeMicrophone(
      settings: settings,
      languageCustomizationID: languageCustomizationID,
      configureSession: false,
      callback: callback
    )
  }

  @objc func stopStreaming() {
    self.isListening = false
    speechToText?.stopRecognizeMicrophone()
  }

  override func startObserving()
  {
    hasListeners = true
  }

  override func stopObserving()
  {
    hasListeners = false
  }
}
