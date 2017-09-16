//
//  Created by Jeremy Olmsted-Thompson on 12/21/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import "TCDataService.h"

#define TC_DATA_SERVICE_DOMAIN @"TCDataService"

@interface TCDataService ()

@end

@implementation TCDataService

#pragma mark - Initialization

+(TCDataService*)service{
    return [[TCDataService alloc] init];
}

#pragma mark - Request

+(NSURLSession*)urlSession {
    static NSURLSession *sharedSession;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    });
    return sharedSession;
}

-(NSURLSession*)urlSession {
    return [[self class] urlSession];
}

-(NSURLSessionTask*)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
          cachePolicy:(NSURLRequestCachePolicy)cachePolicy
      timeoutInterval:(NSTimeInterval)timeoutInterval
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
    for (NSString *header in headers) {
        [request addValue:[headers objectForKey:header] forHTTPHeaderField:header];
    }
    [request setHTTPShouldUsePipelining:YES];
    [request setHTTPMethod:method];
    [request setHTTPBodyStream:bodyStream];
    NSURLSessionDataTask *dataTask = [[self urlSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (errorHandler) errorHandler(error);
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        NSInteger statusCode = [httpResponse statusCode];
        NSDictionary *responseHeaders = [httpResponse allHeaderFields];
        if (statusCode / 100 == TC_RESPONSE_CLIENT_ERROR / 100 || statusCode / 100 == TC_RESPONSE_SERVER_ERROR / 100) {
            NSString *errorString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:TC_DATA_SERVICE_DOMAIN code:statusCode userInfo:errorInfo];
            if (errorHandler) errorHandler(error);
            return;
        }
        if (receiveHandler) receiveHandler(data, @(statusCode), responseHeaders);
    }];
    [dataTask resume];
    return dataTask;
}

-(NSURLSessionTask*)requestWithURL:(NSURL *)url
               method:(NSString *)method
              headers:(NSDictionary *)headers
                 body:(NSData *)body
       receiveHandler:(void (^)(id, NSNumber *, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError *))errorHandler {
    NSMutableDictionary *newHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    if (body) {
        [newHeaders setObject:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forKey:@"Content-Length"];
    }
    return [self requestWithURL:url
                  method:method
                 headers:newHeaders
              bodyStream:body ? [NSInputStream inputStreamWithData:body] : nil
          receiveHandler:receiveHandler
            errorHandler:errorHandler];
}

-(NSURLSessionTask*)requestWithURL:(NSURL*)url
               method:(NSString*)method
              headers:(NSDictionary*)headers
           bodyStream:(NSInputStream*)bodyStream
       receiveHandler:(void (^)(id, NSNumber*, NSDictionary*))receiveHandler
         errorHandler:(void (^)(NSError*))errorHandler {
    return [self requestWithURL:url
                  method:method
                 headers:headers
              bodyStream:bodyStream 
             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
         timeoutInterval:60.0
          receiveHandler:receiveHandler
            errorHandler:errorHandler];
}

@end
