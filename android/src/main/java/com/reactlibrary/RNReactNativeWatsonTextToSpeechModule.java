package com.reactlibrary;

import android.os.AsyncTask;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.ibm.cloud.sdk.core.security.BearerTokenAuthenticator;
import com.ibm.cloud.sdk.core.security.Authenticator;

import com.ibm.watson.developer_cloud.android.library.audio.StreamPlayer;
import com.ibm.watson.text_to_speech.v1.TextToSpeech;
import com.ibm.watson.text_to_speech.v1.model.SynthesizeOptions;
import com.ibm.cloud.sdk.core.http.HttpMediaType;

import java.io.InputStream;

public class RNReactNativeWatsonTextToSpeechModule extends ReactContextBaseJavaModule {

    private ReactApplicationContext reactContext;
    private TextToSpeech service;
    StreamPlayer streamPlayer;
    private StreamingTask mStreamingTask;


    public RNReactNativeWatsonTextToSpeechModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "RNTextToSpeech";
    }

    @ReactMethod
    public void synthesize(String text, String apiKey, String voice, Promise promise) {
        Authenticator authenticator = new BearerTokenAuthenticator(apiKey);
        service = new TextToSpeech(authenticator);
        service.setServiceUrl("https://api.us-south.text-to-speech.watson.cloud.ibm.com/instances/bbfe8ac3-5b61-4d19-8047-462c995a02fd");

        String voiceName = voice;

        if (voiceName == null || voiceName.isEmpty()) {
            voiceName = SynthesizeOptions.Voice.EN_US_ALLISONV3VOICE;
        }

        SynthesizeOptions synthesizeOptions =
                new SynthesizeOptions.Builder()
                        .text(text)
                        .voice(voiceName)
                        .accept(HttpMediaType.AUDIO_WAV)
                        .build();


        if (mStreamingTask != null) {
            mStreamingTask.cancel(true);
            mStreamingTask = null;

            if(streamPlayer != null){
                streamPlayer.interrupt();
            }
        }

        mStreamingTask = new StreamingTask(synthesizeOptions, promise);
        mStreamingTask.execute();
    }


    private class StreamingTask extends AsyncTask<Void, Integer, Boolean> {
        private SynthesizeOptions synthOptions;
        private Promise streamingPromise;

        public StreamingTask(SynthesizeOptions synthesizeOptions, Promise promise) {
            this.synthOptions = synthesizeOptions;
            streamingPromise = promise;
        }

        @Override
        protected Boolean doInBackground(Void... voids) {
            try {
                streamPlayer = new StreamPlayer();
                InputStream audioTrack = service.synthesize(synthOptions).execute().getResult();

                streamPlayer.playStream(audioTrack);
                return true;
            } catch (Exception e) {
                System.err.println("Error: RNTextToSpeech doInBackground couldn't play stream!");
                return false;
            }
        }

        @Override
        protected void onPostExecute(Boolean result) {
            streamingPromise.resolve(result);
            mStreamingTask = null;
        }
    }
}
