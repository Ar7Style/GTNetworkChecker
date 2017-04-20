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




@end
