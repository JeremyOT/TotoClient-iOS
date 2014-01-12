//
//  Created by Jeremy Olmsted-Thompson on 7/29/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "NSString+TCHash.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (TCHash)

-(NSData*)dataWithSHA256Hash {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char buffer[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([data bytes], (CC_LONG)[data length], buffer);
    return [NSData dataWithBytes:buffer length:CC_SHA256_DIGEST_LENGTH];
}

-(NSString*)stringWithSHA256Hash {
    NSData *hash = [self dataWithSHA256Hash];
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH];
    const char *bytes = [hash bytes];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", bytes[i]];
    }
    return output;
}

@end
