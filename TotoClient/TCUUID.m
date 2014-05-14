//
//  Created by Jeremy Olmsted-Thompson on 11/11/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "TCUUID.h"

@implementation TCUUID

+(NSString*)generateUUID {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    return uuidString;
}

@end
