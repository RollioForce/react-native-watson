//
//  RNTextToSpeech.m
//  RNBluemixBoilerplate
//
//  Created by Patrick cremin on 8/2/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

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

