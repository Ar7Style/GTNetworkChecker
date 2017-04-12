//
//  GTUserDataModel.h
//  GTNetworkChecker
//
//  Created by Tareyev Gregory on 09.04.17.
//  Copyright © 2017 Ar7Style. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTUserDataModel : NSObject

@property NSString* carrier;
@property NSString* longitude;
@property NSString* latitude;
@property NSString* cityName;


-(instancetype)initWithDictionary:(NSDictionary*)dict;


@end
