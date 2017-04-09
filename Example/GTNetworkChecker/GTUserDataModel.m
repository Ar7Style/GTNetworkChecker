//
//  GTUserDataModel.m
//  GTNetworkChecker
//
//  Created by Tareyev Gregory on 09.04.17.
//  Copyright © 2017 Ar7Style. All rights reserved.
//

#import "GTUserDataModel.h"

@implementation GTUserDataModel

-(instancetype)initWithDictionary:(NSDictionary*)dict {
    self = [super init];
    if (self) {
        _carrier = [dict valueForKey:@"carrier"];
    }
    return self;
}


@end
