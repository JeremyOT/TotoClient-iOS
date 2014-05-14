//
//  Created by Jeremy Olmsted-Thompson on 12/21/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TC_RESPONSE_OK 200
#define TC_RESPONSE_CLIENT_ERROR 400
#define TC_RESPONSE_SERVER_ERROR 500

@interface TCDataService : NSObject <NSURLConnectionDelegate>

@property(nonatomic,strong) NSURL *requestURL;
@property(nonatomic) NSInteger statusCode;
@property(nonatomic,readonly,getter = isInProgress) BOOL inProgress;

// Response properties
@property(nonatomic, strong, readonly) NSDictionary *responseHeaders;
@property(nonatomic, readonly) long long expectedContentLength;
@property(nonatomic, strong, readonly) NSString *textEncodingName;
@property(nonatomic, strong, readonly) NSString *MIMEType;
@property(nonatomic, strong, readonly) NSString *suggestedFilename;
@property(nonatomic, strong) NSRunLoop *runLoop;

+ (TCDataService*)service;

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
          cachePolicy:(NSURLRequestCachePolicy)cachePolicy
      timeoutInterval:(NSTimeInterval)timeoutInterval
       receiveHandler:(void (^)(id response, NSNumber *status, NSDictionary *headers))receiveHandler
         errorHandler:(void (^)(NSError *error))errorHandler;

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
       receiveHandler:(void (^)(id response, NSNumber *status, NSDictionary *headers))receiveHandler
         errorHandler:(void (^)(NSError *error))errorHandler;

-(void)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
                 body:(NSData*)body
       receiveHandler:(void (^)(id response, NSNumber *status, NSDictionary *headers))receiveHandler
         errorHandler:(void (^)(NSError *error))errorHandler;

- (void)cancel;

@end
