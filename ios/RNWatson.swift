//
//  Created by Patrick cremin on 8/2/17.
//
import SpeechToText
import AVFoundation
import IBMSwiftSDKCore

// SpeechToText
@objc(RNSpeechToText)
class RNSpeechToText: RCTEventEmitter {

  var accumulator = "";
  var speechToTextSession: SpeechToTextSession?
  var hasListeners = false
  var isListening = false;

  static let sharedInstance = RNSpeechToText()

  override func supportedEvents() -> [String]! {
    return ["StreamingText"]
  }

  @objc func startStreaming(_ accessToken: String, config: [String: Any], errorCallback: @escaping RCTResponseSenderBlock) {

    do {
      let audioSession = AVAudioSession.sharedInstance();

      try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
      try audioSession.setActive(true)
    } catch {
      print(error)
    }

    self.isListening = true
    self.accumulator = ""

    let languageCustomizationID = config["languageCustomizationId"] as? String
    let acousticCustomizationID = config["acousticCustomizationId"] as? String

    let authenticator = BearerTokenAuthenticator(bearerToken: accessToken)

    speechToTextSession = SpeechToTextSession(
      authenticator: authenticator,
      languageCustomizationID: languageCustomizationID,
      acousticCustomizationID: acousticCustomizationID,
      learningOptOut: true
    )

    speechToTextSession?.onError = { error in
      self.isListening = false
      errorCallback([error])
    }

    speechToTextSession?.onResults = { payload in
      if (self.hasListeners) {
        let isFinal = payload.results?.last?.final ?? true
        let transcript = payload.results?.last?.alternatives.last?.transcript ?? ""
        var newTranscript = self.accumulator + transcript;
        
        if(isFinal){
            let range = NSRange(0..<newTranscript.utf16.count)
            let isSpellingRegex = try! NSRegularExpression(pattern: "[A-Z]\\.\\s[A-Z]\\.\\s$")
            let isSpelling = isSpellingRegex.firstMatch(in: newTranscript, options: [], range: range) != nil
            
            if(isSpelling) {
                let lastDotRegex = try! NSRegularExpression(pattern: "(.*)\\.\\s$")
                newTranscript = lastDotRegex.stringByReplacingMatches(in: newTranscript, options: [], range: range, withTemplate: "$1.. ")
            }
        }

        self.sendEvent(withName: "StreamingText", body: [
          "isListening": self.isListening,
          "isLoading": !isFinal,
          "text": newTranscript
        ])
        
        if(isFinal){
            self.accumulator = newTranscript;
        }
      }
    }

    var settings = RecognitionSettings(contentType: "audio/ogg;codecs=opus")
    settings.interimResults = true
    settings.smartFormatting = true

    speechToTextSession?.connect()
    speechToTextSession?.startRequest(settings: settings)
    speechToTextSession?.startMicrophone()
  }

  @objc func stopStreaming() {
    self.isListening = false
    speechToTextSession?.stopMicrophone()
    speechToTextSession?.stopRequest()
    speechToTextSession?.disconnect()
  }

  override func startObserving() {
    hasListeners = true
  }

  override func stopObserving() {
    hasListeners = false
  }
}
