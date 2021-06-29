package com.reactlibrary;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.bridge.Arguments;

import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.ibm.cloud.sdk.core.security.BearerTokenAuthenticator;
import com.ibm.cloud.sdk.core.security.Authenticator;
import com.ibm.watson.developer_cloud.android.library.audio.MicrophoneInputStream;
import com.ibm.watson.developer_cloud.android.library.audio.utils.ContentType;
import com.ibm.watson.speech_to_text.v1.SpeechToText;
import com.ibm.watson.speech_to_text.v1.model.RecognizeWithWebsocketsOptions;
import com.ibm.watson.speech_to_text.v1.model.SpeechRecognitionResults;
import com.ibm.watson.speech_to_text.v1.websocket.BaseRecognizeCallback;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RNReactNativeWatsonSpeechToTextModule extends ReactContextBaseJavaModule {

    private ReactApplicationContext reactContext;
    private SpeechToText speechService;
    private MicrophoneInputStream capture;
    private Boolean isListening = false;
    private Callback errorCallback;

    public RNReactNativeWatsonSpeechToTextModule(ReactApplicationContext reactContext) {
        super(reactContext);

        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "RNSpeechToText";
    }

    @ReactMethod
    public void startStreaming(String apiKey, ReadableMap config, Callback errorCallback) {
        Authenticator authenticator = new BearerTokenAuthenticator(apiKey);
        speechService = new SpeechToText(authenticator);

        this.errorCallback = errorCallback;
        capture = new MicrophoneInputStream(true);
        String languageId = config.getString("languageCustomizationId");
        String acousticId = config.getString("acousticCustomizationId");

        try {
            RecognizeWithWebsocketsOptions recognizeOptions = new RecognizeWithWebsocketsOptions.Builder()
                .audio(capture)
                .contentType(ContentType.OPUS.toString())
                .smartFormatting(true)
                .acousticCustomizationId(acousticId)
                .languageCustomizationId(languageId)
                .interimResults(true)
                .build();

            speechService.recognizeUsingWebSocket(recognizeOptions, new MicrophoneRecognizeDelegate(reactContext, errorCallback));
            isListening = true;
        } catch (Exception e) {
            isListening = false;
             errorCallback.invoke(e.toString());
        }
    }

    @ReactMethod
    public void stopStreaming() {
        try {
            capture.close();
            isListening = false;
        } catch (Exception e) {
           errorCallback.invoke(e.toString());
            isListening = false;
        }
    }

    private class MicrophoneRecognizeDelegate extends BaseRecognizeCallback {

        private ReactApplicationContext reactContext;
        private Callback errorCallback;
        private String stringAccumulator = "";

        public MicrophoneRecognizeDelegate(ReactApplicationContext reactContext, Callback errorCallback) {
            this.reactContext = reactContext;
            this.errorCallback = errorCallback;
        }

        @Override
        public void onTranscription(SpeechRecognitionResults speechResults) {
            if (speechResults.getResults() != null && !speechResults.getResults().isEmpty()) {
                String text = speechResults.getResults().get(0).getAlternatives().get(0).getTranscript();
                boolean isFinal = speechResults.getResults().get(0).isXFinal();
                String newTranscript = this.stringAccumulator + text;

                if(isFinal) {
                    Matcher isSpellingMatcher = Pattern.compile("[A-Z]\\.\\s[A-Z]\\.\\s$").matcher(newTranscript);
                    if (isSpellingMatcher.find()) {
                        Matcher lastDotMatcher = Pattern.compile("(.*)\\.\\s$").matcher(newTranscript); 
                        newTranscript = lastDotMatcher.replaceAll("$1.. ");
                    }
                }

                WritableMap body = Arguments.createMap();
                body.putString("text", newTranscript);
                body.putBoolean("isListening", isListening);
                body.putBoolean("isLoading", !isFinal);

                if(isFinal){
                    this.stringAccumulator = newTranscript;
                }

                reactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit("StreamingText", body);
            }
        }

        @Override
        public void onDisconnected() {
            isListening = false;
        }
        @Override public void onError(Exception e) {
           errorCallback.invoke(e.toString());
            isListening = false;
        }

    }
}
