//
//  Created by Jeremy Olmsted-Thompson on 7/29/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TCHash)

-(NSData*)dataWithSHA256Hash;
-(NSString*)stringWithSHA256Hash;

@end
