package com.reactlibrary;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.ibm.cloud.sdk.core.security.BearerTokenAuthenticator;
import com.ibm.cloud.sdk.core.security.Authenticator;

import com.ibm.watson.text_to_speech.v1.TextToSpeech;
import com.ibm.watson.text_to_speech.v1.model.SynthesizeOptions;
import com.ibm.cloud.sdk.core.http.HttpMediaType;

import java.io.InputStream;

import com.ibm.watson.text_to_speech.v1.util.WaveUtils;

import java.io.File;
import java.io.*;
import java.net.URLEncoder;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.util.UUID;


public class RNReactNativeWatsonTextToSpeechModule extends ReactContextBaseJavaModule {

    private ReactApplicationContext reactContext;
    private TextToSpeech service;

    public RNReactNativeWatsonTextToSpeechModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "RNTextToSpeech";
    }

      private static void writeToFile(InputStream in, File file) {
        try {
          OutputStream out = new FileOutputStream(file);
          byte[] buf = new byte[1024];
          int len;
          while ((len = in.read(buf)) > 0) {
            out.write(buf, 0, len);
          }
          out.close();
          in.close();
        } catch (Exception e) {
          e.printStackTrace();
        }
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
                        .accept(HttpMediaType.AUDIO_OGG_VORBIS)
                        .build();

        try {
            InputStream in = service.synthesize(synthesizeOptions).execute().getResult();
            String fileName = "" + System.currentTimeMillis();
            File outputDir = reactContext.getCacheDir();
            File outputFile = File.createTempFile(fileName, ".ogg", outputDir);
            writeToFile(in, outputFile);

         promise.resolve(outputFile.getPath());
        } catch (Exception e) {
            promise.reject(e);
            System.err.println(e);
        }
    }
}
