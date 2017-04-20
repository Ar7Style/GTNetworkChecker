//
//  GTViewController.h
//  GTNetworkChecker
//
//  Created by Ar7Style on 04/04/2017.
//  Copyright (c) 2017 Ar7Style. All rights reserved.
//

@import UIKit;
#import <MessageUI/MessageUI.h>
#import <GBPing/GBPing.h>

@interface GTViewController : UIViewController<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSURLSessionStreamDelegate, MFMailComposeViewControllerDelegate, GBPingDelegate> {
    MFMailComposeViewController *mailComposer;
}
@property GBPing* ping;
@property NSString* infoAboutPing;
@property double bestPing;
@property double worstPing;

@end
