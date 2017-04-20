/*
 Copyright (C) 2017 Tareyev. All Rights Reserved.
 
 Abstract:
 Application delegate class.
 */

#import "GTViewController.h"
#import <GTNetworkChecker/Reachability.h>
#import "GTUserDataModel.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>



@interface GTViewController () <NSURLSessionDelegate, NSURLSessionDataDelegate, CLLocationManagerDelegate> {
    NSString* internetSpeed;
    NSTimeInterval startTime;
    CLLocationManager* locationManager;
    BOOL isWaitingForLocation;
    NSString* requestId;
    CLGeocoder *ceo;
    NSString* locatedAtGlobal;
    BOOL isReachable;
    double lastSpeed;
    double averageSpeed;
}

@property (nonatomic, weak) IBOutlet UILabel* summaryLabel;

@property (weak, nonatomic) IBOutlet UIButton *complineButton;
@property (nonatomic, weak) IBOutlet UITextField *remoteHostLabel;
@property (nonatomic, weak) IBOutlet UIImageView *remoteHostImageView;
@property (nonatomic, weak) IBOutlet UITextField *remoteHostStatusField;

@property (nonatomic, weak) IBOutlet UIImageView *internetConnectionImageView;
@property (nonatomic, weak) IBOutlet UITextField *internetConnectionStatusField;

@property (weak, nonatomic) IBOutlet UILabel *speedLabel;

@property (weak, nonatomic) IBOutlet UILabel *bestPingLabel;
@property (weak, nonatomic) IBOutlet UILabel *worstPingLabel;
@property (weak, nonatomic) IBOutlet UILabel *pingResultLabel;

@property (nonatomic,strong) GTUserDataModel* userDataModel;

@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;

@end

#pragma mark - Life cycle

@implementation GTViewController

static NSURLSession *_sharedSession;
- (NSURLSession *)backgroundSession
{
    if (!_sharedSession)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"org.cocoapods.demo.GTNetworkChecker-Example"];
            sessionConfiguration.HTTPMaximumConnectionsPerHost = 2;
            _sharedSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                          delegate:self
                                                     delegateQueue:nil];
        });
    }
    return _sharedSession;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    locatedAtGlobal = @"";
    dispatch_async(dispatch_get_main_queue(), ^{
       // _speedLabel.text = @"Calculating your speed . . .";
    });
    [_complineButton.layer setCornerRadius:_complineButton.frame.size.height/2];
    [_complineButton setBackgroundColor:[UIColor whiteColor]];
    
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    NSLog(@"Current Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
    [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *note)
    {
        NSLog(@"New Radio Access Technology: %@", telephonyInfo.currentRadioAccessTechnology);
    }];

    /*
     Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateSpeedLabel:) name:@"updateSpeedLabel" object:nil];
    
    //Change the host name here to change the server you want to monitor.
    NSString *remoteHostName = @"www.apple.com";
    NSString *remoteHostLabelFormatString = NSLocalizedString(@"Remote Host: %@", @"Remote host label format string");
    self.remoteHostLabel.text = [NSString stringWithFormat:remoteHostLabelFormatString, remoteHostName];
    
    self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
    [self.hostReachability startNotifier];
    [self updateInterfaceWithReachability:self.hostReachability];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [self updateInterfaceWithReachability:self.internetReachability];
    
    [self getPingLatency];
    [self getCarrier];
    [self getInternetSpeed];
    
}

-(void)updateSpeedLabel:(NSNotification*)aNotification {
    internetSpeed = isReachable ? aNotification.object :  @"Internet is unavailable";
    NSString* speed = isReachable ? [NSString stringWithFormat:@"Your speed is : %@ Mb/s", internetSpeed] : @"Internet is unavailable";
    self.speedLabel.text = speed;
}

-(void)getCarrier {
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    self.userDataModel = [[GTUserDataModel alloc] initWithDictionary:@{@"carrier" : carrier.carrierName ? carrier.carrierName : @"simulator"}];
    NSLog(@"User's carrier: %@", self.userDataModel.carrier);
}

#pragma mark - Reachability methods


/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    if ([curReach isEqual:NotReachable])
        isReachable = NO;
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
    [self getPingLatency];
    [self getInternetSpeed];

}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    if (reachability == self.hostReachability)
    {
        [self configureTextField:self.remoteHostStatusField imageView:self.remoteHostImageView reachability:reachability];
        NetworkStatus netStatus = [reachability currentReachabilityStatus];
        BOOL connectionRequired = [reachability connectionRequired];
        
       // self.summaryLabel.hidden = (netStatus != ReachableViaWWAN);
        NSString* baseLabelText = @"";
        
        if (connectionRequired)
        {
            baseLabelText = NSLocalizedString(@"Cellular data network is available.\nInternet traffic will be routed through it after a connection is established.", @"Reachability text if a connection is required");
        }
        else
        {
            baseLabelText = NSLocalizedString(@"Cellular data network is active.\nInternet traffic will be routed through it.", @"Reachability text if a connection is not required");
        }
        self.summaryLabel.text = baseLabelText;
    }
    
    if (reachability == self.internetReachability)
    {
        [self configureTextField:self.internetConnectionStatusField imageView:self.internetConnectionImageView reachability:reachability];
    }
    
}


- (void)configureTextField:(UITextField *)textField imageView:(UIImageView *)imageView reachability:(Reachability *)reachability
{
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    BOOL connectionRequired = [reachability connectionRequired];
    NSString* statusString = @"";
    
    switch (netStatus)
    {
        case NotReachable:        {
            statusString = NSLocalizedString(@"Access Not Available", @"Text field text for access is not available");
            imageView.image = [UIImage imageNamed:@"stop-32.png"] ;
            /*
             Minor interface detail- connectionRequired may return YES even when the host is unreachable. We cover that up here...
             */
            connectionRequired = NO;
            isReachable = NO;
            break;
        }
            
        case ReachableViaWWAN:        {
            statusString = NSLocalizedString(@"Reachable WWAN", @"");
            imageView.image = [UIImage imageNamed:@"WWAN5.png"];
            isReachable = YES;
            break;
        }
        case ReachableViaWiFi:        {
            statusString= NSLocalizedString(@"Reachable WiFi", @"");
            imageView.image = [UIImage imageNamed:@"Airport.png"];
            isReachable = YES;
            break;
        }
    }
    
    if (connectionRequired)
    {
        NSString *connectionRequiredFormatString = NSLocalizedString(@"%@, Connection Required", @"Concatenation of status string with connection requirement");
        statusString= [NSString stringWithFormat:connectionRequiredFormatString, statusString];
    }
    textField.text= statusString;
}


#pragma mark - Ping detection methods

-(void)getPingLatency {
    _bestPingLabel.text = @"Checking new best ping . . .";
    _worstPingLabel.text = @"Checking new worst ping . . .";
    _pingResultLabel.text = @"Counting new ping results . . .";
    _bestPing = 15.0;
    _worstPing = 0;
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
                
                _bestPingLabel.text = [NSString stringWithFormat:@"Best ping is %f", _bestPing];
                _worstPingLabel.text = [NSString stringWithFormat:@"Worst ping is %f", _worstPing];
                _pingResultLabel.text = ((_bestPing + _worstPing)/2 < 1.0 && isReachable) ? @"Your ping is fine" : @"Ping is too big, you may complain on it";
                
                    
            }];
        }
        else {
            NSLog(@"failed to start");
        }
    }];
}

-(void)ping:(GBPing *)pinger didReceiveReplyWithSummary:(GBPingSummary *)summary {
    NSLog(@"REPLY>  %f", summary.rtt);
    if (summary.rtt != 0) {
    _bestPing = (_bestPing > summary.rtt) ? summary.rtt : _bestPing;
    _worstPing = (_worstPing < summary.rtt) ? summary.rtt : _worstPing;
    }
}

-(void)ping:(GBPing *)pinger didReceiveUnexpectedReplyWithSummary:(GBPingSummary *)summary {
    // NSLog(@"BREPLY> %f", summary.rtt);
    //    _bestPing = (_bestPing > summary.rtt) ? summary.rtt : _bestPing;
    //    _worstPing = (_worstPing < summary.rtt) ? summary.rtt : _worstPing;
    if (summary.rtt != 0) {
        _bestPing = (_bestPing > summary.rtt) ? summary.rtt : _bestPing;
        _worstPing = (_worstPing < summary.rtt) ? summary.rtt : _worstPing;
    }
}

-(void)ping:(GBPing *)pinger didSendPingWithSummary:(GBPingSummary *)summary {
    // NSLog(@"SENT>   %f", summary.rtt);
    //    _bestPing = (_bestPing > summary.rtt) ? summary.rtt : _bestPing;
    //    _worstPing = (_worstPing < summary.rtt) ? summary.rtt : _worstPing;
    if (summary.rtt != 0) {
        _bestPing = (_bestPing > summary.rtt) ? summary.rtt : _bestPing;
        _worstPing = (_worstPing < summary.rtt) ? summary.rtt : _worstPing;
    }
}

-(void)ping:(GBPing *)pinger didTimeoutWithSummary:(GBPingSummary *)summary {
  //  NSLog(@"TIMOUT> %f", summary.rtt);
    if (summary.rtt != 0) {
    _bestPing = (_bestPing > summary.rtt) ? summary.rtt : _bestPing;
    _worstPing = (_worstPing < summary.rtt) ? summary.rtt : _worstPing;
    }
}

-(void)ping:(GBPing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"FAIL>   %@", error);
    [self getPingLatency];
}

-(void)ping:(GBPing *)pinger didFailToSendPingWithSummary:(GBPingSummary *)summary error:(NSError *)error {
 //   NSLog(@"FSENT>  %f, %@", summary.rtt, error);
    if (summary.rtt != 0) {
    _bestPing = (_bestPing > summary.rtt) ? summary.rtt : _bestPing;
    _worstPing = (_worstPing < summary.rtt) ? summary.rtt : _worstPing;
    }
}


#pragma mark - Actions

- (IBAction)complinePressed:(id)sender {
    NSLog(@"compline button pressed");
    isWaitingForLocation = YES;
                locationManager = [[CLLocationManager alloc] init];
                locationManager.delegate = self;
                BOOL isAuthorized = [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
                if (isAuthorized) {
                        [locationManager startUpdatingLocation];
                    }
                else {
                        [locationManager requestAlwaysAuthorization];
                    }
}

#pragma mark - CoreLocation delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *currentLocation = locations.firstObject;
    if (currentLocation != nil && isWaitingForLocation) {
        NSString* longitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        NSString* latitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        
        ceo = [[CLGeocoder alloc]init];
        CLLocation *loc = [[CLLocation alloc]initWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
        [ceo reverseGeocodeLocation:loc
                  completionHandler:^(NSArray *placemarks, NSError *error) {
                      CLPlacemark *placemark = [placemarks objectAtIndex:0];
                      NSLog(@"placemark %@",placemark);
                      //String to hold address
                      NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
                      NSLog(@"addressDictionary %@", placemark.addressDictionary);
                      locatedAtGlobal = locatedAt;
                      NSLog(@"placemark %@",placemark.region);
                      NSLog(@"placemark %@",placemark.country);  // Give Country Name
                      NSLog(@"placemark %@",placemark.locality); // Extract the city name
                      NSLog(@"location %@",placemark.name);
                      NSLog(@"location %@",placemark.ocean);
                      NSLog(@"location %@",placemark.postalCode);
                      NSLog(@"location %@",placemark.subLocality);
                      
                      NSLog(@"location %@",placemark.location);
                      //Print the location to console
                      NSLog(@"I am currently at %@",locatedAt);
                      
                      
                    //  _City.text=[placemark.addressDictionary objectForKey:@"City"];
                      [locationManager stopUpdatingLocation];
                      mailComposer = [[MFMailComposeViewController alloc]init];
                      mailComposer.mailComposeDelegate = self;
                      [mailComposer setToRecipients:@[@"tareyev.project@mail.ru"]];
                      [mailComposer setSubject:@"Connection troubles"];
                      [mailComposer setMessageBody:[NSString stringWithFormat:@"I've problem with internet connection at: %@ \n My carrier: %@ \n internet speed: %@, iOS version: %ld.%ld.%ld",
                                                    locatedAtGlobal,
                                                    self.userDataModel.carrier,
                                                    internetSpeed,
                                                    (long)[[NSProcessInfo processInfo] operatingSystemVersion].majorVersion,
                                                    [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion,
                                                    [[NSProcessInfo processInfo] operatingSystemVersion].patchVersion]
                                            isHTML:NO];
                      
                      if ([MFMailComposeViewController canSendMail])
                          [self presentViewController:mailComposer animated:YES completion:nil];
                  }
         
         ];
        
        isWaitingForLocation = NO;
        
    }
    [locationManager stopUpdatingLocation];

}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    [locationManager stopUpdatingLocation];
    
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if(status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse){
        [locationManager startUpdatingLocation];
    }
}

#pragma mark - mail compose delegate
-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (result) {
        NSLog(@"Result : %ld",(long)result);
    }
    if (error) {
        NSLog(@"Error : %@",error);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - NSUrlSession methods

-(void)getInternetSpeed {
    // Creating session configurations
    NSLog(@"Speed label: %@", self.speedLabel);
    //self.speedLabel.text = @"Calculating your speed . . .";
    NSURLSessionConfiguration *defaultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSessionConfiguration *ephemeralConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier: @"org.cocoapods.demo.GTNetworkChecker-Example"];
    
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
    id <NSURLSessionDelegate> delegate = [[GTViewController alloc] init];
    NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
    
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfiguration delegate:delegate delegateQueue:operationQueue];
    NSURLSession *ephemeralSession = [NSURLSession sessionWithConfiguration:ephemeralConfiguration delegate:delegate delegateQueue:operationQueue];
    NSURLSession *backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:delegate delegateQueue:operationQueue];
    NSURL *url = [NSURL URLWithString:@"https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/ObjC_classic/FoundationObjC.pdf"];
    if (!isReachable)
        self.speedLabel.text = @"Internet is unavailable";
    lastSpeed = 0;
    averageSpeed = lastSpeed;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    NSURLSessionDownloadTask *downloadTask = [backgroundSession downloadTaskWithURL:url];
    [downloadTask resume];
    
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        lastSpeed = totalBytesWritten / ([NSDate timeIntervalSinceReferenceDate] - startTime);
        //NSLog(@"internet speed: %f Mb/s", lastSpeed*1024.0*10.);
       
        averageSpeed = lastSpeed;
        averageSpeed = 0.005 * lastSpeed + (1-0.005) * averageSpeed;
        NSString* speedString =[NSString stringWithFormat:@"%f", averageSpeed*1024.*10.];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"updateSpeedLabel" object:speedString];
    }];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
  //  NSLog(@"Session %@ download task %@ resumed at offset %lld bytes out of an expected %lld bytes.\n", session, downloadTask, fileOffset, expectedTotalBytes);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
   // NSLog(@"Session %@ download task %@ finished downloading to URL %@\n", session, downloadTask, location);
    
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


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}


@end
