//
//  GTViewController.h
//  GTNetworkChecker
//
//  Created by Ar7Style on 04/04/2017.
//  Copyright (c) 2017 Ar7Style. All rights reserved.
//

@import UIKit;
#import <MessageUI/MessageUI.h>

@interface GTViewController : UIViewController<MFMailComposeViewControllerDelegate> {
    MFMailComposeViewController *mailComposer;
}

@end
