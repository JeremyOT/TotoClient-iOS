//
//  HMAC.m
//  FanStand
//
//  Created by Jeremy Olmsted-Thompson on 12/21/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import "HMAC.h"
#import <CommonCrypto/CommonHMAC.h>
#import "NSData+Base64.h"

@implementation HMAC

+(NSData*)SHA1DigestWithKey:(NSData*)key data:(NSData*)data {
    unsigned char hmac[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, [key bytes], [key length], [data bytes], [data length], hmac);
    return [NSData dataWithBytes:hmac length:sizeof(hmac)];
}

+(NSString*)SHA1HexDigestWithKey:(NSData*)key data:(NSData*)data {
    NSString *hmac = [[HMAC SHA1DigestWithKey:key data:data] description];
    return [[hmac substringWithRange:NSMakeRange(1, [hmac length] - 2)] stringByReplacingOccurrencesOfString:@" " withString:@""];
}

+(NSString *)SHA1Base64DigestWithKey:(NSData *)key data:(NSData *)data {
    NSString *hmac = [[HMAC SHA1DigestWithKey:key data:data] stringByBase64Encoding];
    return hmac;
}

@end
