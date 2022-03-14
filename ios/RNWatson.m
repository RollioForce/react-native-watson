
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(RNSpeechToText, RCTEventEmitter)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

RCT_EXTERN_METHOD(startStreaming: (NSString *)accessToken config:(NSDictionary *)config errorCallback:(RCTResponseSenderBlock *)errorCallback)

RCT_EXTERN_METHOD(stopStreaming)

@end


@interface RCT_EXTERN_MODULE(RNTextToSpeech, NSObject)

RCT_EXTERN_METHOD(synthesize:(NSString *)text accessToken:(NSString *)accessToken voice:(NSString *)voice resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject )

RCT_EXTERN_METHOD(stopAudio)

@end

