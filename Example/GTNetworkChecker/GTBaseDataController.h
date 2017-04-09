//
//  GTBaseDataController.h
//  GTNetworkChecker
//
//  Created by Tareyev Gregory on 07.04.17.
//  Copyright © 2017 Ar7Style. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GBPing/GBPing.h>
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef void (^CompletionHandler)();

@interface GTBaseDataController : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSURLSessionStreamDelegate, GBPingDelegate>

@property NSMutableDictionary <NSString *, CompletionHandler>*completionHandlers;
@property CFAbsoluteTime startTime;
@property CFAbsoluteTime stopTime;
@property GBPing* ping;

+ (instancetype)sharedDataController;
-(NSString*)getInternetSpeed;
-(void)getPingLatency;

@end
NS_ASSUME_NONNULL_END
