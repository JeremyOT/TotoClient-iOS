//
//  HMAC.h
//  FanStand
//
//  Created by Jeremy Olmsted-Thompson on 12/21/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMAC : NSObject

+(NSData*)SHA1DigestWithKey:(NSData*)key data:(NSData*)data;
+(NSString*)SHA1HexDigestWithKey:(NSData*)key data:(NSData*)data;
+(NSString*)SHA1Base64DigestWithKey:(NSData*)key data:(NSData*)data;

@end
