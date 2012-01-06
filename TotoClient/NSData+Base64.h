//
//  NSData+Base64.h
//
//  Created by Jeremy Olmsted-Thompson on 12/21/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Base64)

-(NSString*)stringByBase64Encoding;
+(NSData*)dataByBase64DecodingString:(NSString*)base64String;

@end
