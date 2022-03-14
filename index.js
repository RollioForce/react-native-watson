import {NativeEventEmitter, NativeModules} from "react-native";

const {RNSpeechToText, RNTextToSpeech} = NativeModules;

module.exports = {

    TextToSpeech: {
        synthesize: function (text, accessToken, voice) {
            return RNTextToSpeech.synthesize(text, accessToken, voice);
        },

        stopSound: function () {
            return RNTextToSpeech.stopSound();
        }
    },
    SpeechToText: {
        speechToTextEmitter: new NativeEventEmitter(RNSpeechToText),

        startStreaming({
                           accessToken,
                           acousticCustomizationId,
                           callback,
                           languageCustomizationId
                       }) {
            this.speechToTextEmitter.removeAllListeners("StreamingText");

            this.subscription = this.speechToTextEmitter.addListener(
                "StreamingText",
                ({isListening, isLoading, text}) => {
                    callback(null, text, isLoading);

                    if (this.subscription && !isListening && !isLoading) {
                        this.subscription.remove();
                    }
                }
            );

            const onError = error => {
                callback(error || 'Watson iOS SDK Error');

                if (this.subscription) {
                    this.speechToTextEmitter.removeAllListeners("StreamingText");
                }
            };

            RNSpeechToText.startStreaming(
                accessToken,
                {
                    acousticCustomizationId,
                    languageCustomizationId
                },
                onError
            );
        },

        stopStreaming() {
            RNSpeechToText.stopStreaming();
        }
    }
};
