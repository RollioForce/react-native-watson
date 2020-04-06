# react-native-watson

This is a fork of [react-native-watson](https://github.com/pwcremin/react-native-watson)


## Overview
React Native module (ios and ~~android~~) for using ~~select Watson services~~ Watson Speech-To-Text.  Access to Watson services is provided by wrapping the [Watson Developer Cloud](https://github.com/watson-developer-cloud/swift-sdk)

### Services

* [Speech to Text](#speech-to-text)

If you would like to see more services implemented please create an issue for it.

## Install

```shell
npm install --save @rollioforce/react-native-watson

```
## iOS

### Manually link

Copy RNWatson.m and RNWatson.swift from node_modules/react-native-watson/ios into your project.  You will be prompted to create a bridging header.  Accept and place the below into the header:

```obj-c
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
```

#### Dependency Management

You can install Cocoapods with [RubyGems](https://rubygems.org/):

```bash
$ sudo gem install cocoapods
```

If your project does not yet have a Podfile, use the `pod init` command in the root directory of your project. To install the Swift SDK using Cocoapods, add the services you will be using to your Podfile as demonstrated below (substituting `MyApp` with the name of your app). The example below shows all of the currently available services; your Podfile should only include the services that your app will use.

```ruby
use_frameworks!

target 'MyApp' do
  pod 'IBMWatsonRestKit', '~> 3.0.3'
  pod 'IBMWatsonSpeechToTextV1', '~> 3.2.0'
end
```

Run the `pod install` command, and open the generated `.xcworkspace` file. To update to newer releases, use `pod update`.

## Service Instances

Services are instantiated using an [IAM](https://www.ibm.com/security/identity-access-management) access token, see [here](https://cloud.ibm.com/docs/iam?topic=iam-iamtoken_from_apikey) for more information on generating an access token.

## Speech to Text

The IBM Watson Speech to Text service enables you to add speech transcription capabilities to your application. It uses machine intelligence to combine information about grammar and language structure to generate an accurate transcription. 

```javascript
import { SpeechToText } from '@rollioforce/react-native-watson';

SpeechToText.startStreaming({
  accessToken: 'MY-IAM-TOKEN'
  callback: (error, text) => {
    console.log(text)
  }
})

SpeechToText.stopStreaming()   
```
