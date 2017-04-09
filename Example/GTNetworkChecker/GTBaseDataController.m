//
//  GTBaseDataController.m
//  GTNetworkChecker
//
//  Created by Tareyev Gregory on 07.04.17.
//  Copyright © 2017 Ar7Style. All rights reserved.
//

#import "GTBaseDataController.h"
#import <GTNetworkChecker/Reachability.h>
#import <GBPing/GBPing.h>
@import Foundation;

@implementation GTBaseDataController

static GTBaseDataController *_sharedDataController = nil;


+ (instancetype)sharedDataController
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDataController = [[GTBaseDataController alloc]init];
        Reachability* reach = [Reachability reachabilityForInternetConnection];
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(reachabilityChangedBase:)
//                                                     name:kReachabilityChangedNotification
//                                                   object:nil];
        [reach startNotifier];
    });
    return _sharedDataController;
}

- (void) reachabilityChangedBase:(NSNotification*)aNotification {
    
}

#pragma mark - Ping detection methods

-(void)getPingLatency {
    self.ping = [[GBPing alloc] init];
    self.ping.host = @"google.com";
    self.ping.delegate = self;
    self.ping.timeout = 1.0;
    self.ping.pingPeriod = 0.9;
    
    [self.ping setupWithBlock:^(BOOL success, NSError *error) { //necessary to resolve hostname
        if (success) {
            //start pinging
            [self.ping startPinging];
            
            //stop it after 5 seconds
            [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
                NSLog(@"stop it");
                [self.ping stop];
                self.ping = nil;
            }];
        }
        else {
            NSLog(@"failed to start");
        }
    }];
}

-(void)ping:(GBPing *)pinger didReceiveReplyWithSummary:(GBPingSummary *)summary {
    NSLog(@"REPLY>  %@", summary);
}

-(void)ping:(GBPing *)pinger didReceiveUnexpectedReplyWithSummary:(GBPingSummary *)summary {
    NSLog(@"BREPLY> %@", summary);
}

-(void)ping:(GBPing *)pinger didSendPingWithSummary:(GBPingSummary *)summary {
    NSLog(@"SENT>   %@", summary);
}

-(void)ping:(GBPing *)pinger didTimeoutWithSummary:(GBPingSummary *)summary {
    NSLog(@"TIMOUT> %@", summary);
}

-(void)ping:(GBPing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"FAIL>   %@", error);
}

-(void)ping:(GBPing *)pinger didFailToSendPingWithSummary:(GBPingSummary *)summary error:(NSError *)error {
    NSLog(@"FSENT>  %@, %@", summary, error);
}

#pragma mark - NSUrlSession methods

-(NSString*)getInternetSpeed {
    NSString* internetSpeed = @"";
    
    // Creating session configurations
    NSURLSessionConfiguration *defaultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSessionConfiguration *ephemeralConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier: @"com.myapp.networking.background"];
    
    // Configuring caching behavior for the default session
    NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *cachePath = [cachesDirectory stringByAppendingPathComponent:@"MyCache"];
    
    /* Note:
     iOS requires the cache path to be
     a path relative to the ~/Library/Caches directory,
     but OS X expects an absolute path.
     */
#if TARGET_OS_OSX
    cachePath = [cachePath stringByStandardizingPath];
#endif
    
    NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:16384 diskCapacity:268435456 diskPath:cachePath];
    defaultConfiguration.URLCache = cache;
    defaultConfiguration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    
    // Creating sessions
    id <NSURLSessionDelegate> delegate = [[GTBaseDataController alloc] init];
    NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
    
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfiguration delegate:delegate delegateQueue:operationQueue];
    NSURLSession *ephemeralSession = [NSURLSession sessionWithConfiguration:ephemeralConfiguration delegate:delegate delegateQueue:operationQueue];
    NSURLSession *backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:delegate delegateQueue:operationQueue];
    NSURL *url = [NSURL URLWithString:@"https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/ObjC_classic/FoundationObjC.pdf"];
    NSURLSessionDownloadTask *downloadTask = [backgroundSession downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }];
    [downloadTask resume];
    
    
    return internetSpeed;
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"Session %@ download task %@ wrote an additional %lld bytes (total %lld bytes) out of an expected %lld bytes.\n", session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    //NSLog(@"wrote an additional %lld bytes (total %lld bytes) out of an expected %lld bytes", )
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"Session %@ download task %@ resumed at offset %lld bytes out of an expected %lld bytes.\n", session, downloadTask, fileOffset, expectedTotalBytes);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"Session %@ download task %@ finished downloading to URL %@\n", session, downloadTask, location);
    
    // Perform the completion handler for the current session
   // self.completionHandlers[session.configuration.identifier]();
    
    // Open the downloaded file for reading
    NSError *readError = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:location error:nil];
    // ...
    
    // Move the file to a new URL
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *cacheDirectory = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
    NSError *moveError; //= nil;
    if ([fileManager moveItemAtURL:location toURL:cacheDirectory error:nil]) {
        // ...
    }
}


@end
