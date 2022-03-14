import SpeechToText
import TextToSpeech
import AVFoundation
import IBMSwiftSDKCore

// TextToSpeech
@objc(RNTextToSpeech)
class RNTextToSpeech: NSObject {

  var textToSpeech: TextToSpeech?

  static let sharedInstance = RNTextToSpeech()
  var audioPlayer = AVAudioPlayer()
  private override init() {}


  @objc func synthesize(_ text: String, accessToken: String, voice: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {

    let authenticator = BearerTokenAuthenticator(bearerToken: accessToken)

    textToSpeech = TextToSpeech(authenticator: authenticator)

    textToSpeech?.serviceURL = "https://api.us-south.text-to-speech.watson.cloud.ibm.com/instances/bbfe8ac3-5b61-4d19-8047-462c995a02fd"

    var synthesizeVoice = voice

    if synthesizeVoice.isEmpty {
      synthesizeVoice = "en-GB_KateV3Voice"
    }


    textToSpeech?.synthesize(text: text, accept: "audio/wav", voice: voice) { (response, error) in
        if let error = error {
            print(error)
          reject("500","Failed to synthesize text", error)
        }

        guard let data = response?.result else {
            print("Failed to synthesize text")
          reject("500","Failed to synthesize text", nil)
          return
        }

      self.audioPlayer = try! AVAudioPlayer(data: data)
      self.audioPlayer.prepareToPlay()
      self.audioPlayer.play()
    }
  }

  @objc func stopAudio() -> Void {

    self.audioPlayer.stop()
  }
}

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
