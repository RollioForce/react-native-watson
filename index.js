import { NativeEventEmitter, NativeModules, Platform } from "react-native";

const { RNSpeechToText } = NativeModules;

module.exports = {
  SpeechToText: {
    speechToTextEmitter: new NativeEventEmitter(RNSpeechToText),

    initialize: function(apiKey) {
      RNSpeechToText.initialize(apiKey);
    },

    startStreaming({ callback, languageCustomizationId }) {
      this.speechToTextEmitter.removeAllListeners("StreamingText")

      this.subscription = this.speechToTextEmitter.addListener(
        "StreamingText",
        ({ isListening, isLoading, text }) => {
          callback(null, text, isLoading)

          if (this.subscription && !isListening && !isLoading) {
            this.subscription.remove()
          }
        }
      );

      const onError = (error) => {
        callback(error)

        if (this.subscription) {
          this.speechToTextEmitter.removeAllListeners("StreamingText")
        }
      }

      RNSpeechToText.startStreaming(languageCustomizationId, onError);
    },

    stopStreaming() {
      RNSpeechToText.stopStreaming();
    }
  }
};
