//
//  Created by Jeremy Olmsted-Thompson on 12/20/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import "TCDataService.h"

#define TOTO_ERROR_SERVER 1000
#define TOTO_ERROR_MISSING_METHOD 1002
#define TOTO_ERROR_MISSING_PARAMS 1003
#define TOTO_ERROR_NOT_AUTHORIZED 1004
#define TOTO_ERROR_USER_NOT_FOUND 1005
#define TOTO_ERROR_USER_ID_EXISTS 1006
#define TOTO_ERROR_INVALID_SESSION_ID 1007
#define TOTO_ERROR_INVALID_HMAC 1008
#define TOTO_ERROR_INVALID_RESPONSE_HMAC 1009

@class TotoService;

@protocol TotoServiceAuthenticationDelegate

-(void)totoService:(TotoService*)service
requiresAuthenticationForMethodName:(NSString*)methodName
        parameters:(id)parameters
           headers:(NSDictionary*)headers
useQueryParameters:(BOOL)useQueryParameters
    receiveHandler:(void (^)(id))receiveHandler
      errorHandler:(void (^)(NSError *))errorHandler;

@end

@interface TotoService : TCDataService

@property (readonly) NSURL *serviceURL;
#if !defined NO_BSON && !defined NO_JSON
@property (nonatomic,assign) BOOL usesBSON;
#endif
@property (nonatomic,assign) id<TotoServiceAuthenticationDelegate> authenticationDelegate;

@property (nonatomic, readonly) NSString *userID;
@property (nonatomic, readonly) NSString *sessionID;
@property (nonatomic, readonly) NSTimeInterval sessionExpires;
@property (nonatomic, readonly) NSUInteger queuedRequestCount;
@property (nonatomic, retain) NSDictionary *sessionData;
@property (nonatomic, copy) void (^preflightHandler)(NSData *requestBody, NSMutableDictionary *headers);
@property (nonatomic, assign) BOOL signsRequests;
@property (nonatomic, assign) NSJSONReadingOptions JSONReadingOptions;

+(void)setDefaultRequestHeader:(NSString*)value forKey:(NSString*)key;
+(NSString*)defaultRequestHeaderForKey:(NSString*)key;
+(NSDictionary*)allDefaultRequestHeaders;

+(TotoService*)serviceWithURL:(NSURL*)url;
-(TotoService*)initWithURL:(NSURL*)url;
+(TotoService*)serviceWithURL:(NSURL*)url BSON:(BOOL)bson;
-(TotoService*)initWithURL:(NSURL*)url BSON:(BOOL)bson;

-(void)clearSession;

-(void)authenticateWithUserID:(NSString*)userID
                     password:(NSString*)password 
         additionalParameters:(NSDictionary *)parameters
               receiveHandler:(void (^)(id response))receiveHandler
                 errorHandler:(void (^)(NSError *error))errorHandler;

-(void)createAccountWithUserID:(NSString*)userID
                      password:(NSString*)password 
          additionalParameters:(NSDictionary *)parameters
                receiveHandler:(void (^)(id response))receiveHandler
                  errorHandler:(void (^)(NSError *error))errorHandler;

-(void)totoRequestWithMethodName:(NSString*)method
                      parameters:(id)parameters
                  receiveHandler:(void (^)(id response))receiveHandler
                    errorHandler:(void (^)(NSError *error))errorHandler;

-(void)totoRequestWithMethodName:(NSString *)method
                      parameters:(id)parameters
                         headers:(NSDictionary*)headers
                  receiveHandler:(void (^)(id))receiveHandler
                    errorHandler:(void (^)(NSError *))errorHandler;

-(void)totoRequestWithMethodName:(NSString*)method
                      parameters:(id)parameters
              useQueryParameters:(BOOL)useQueryParameters
                  receiveHandler:(void (^)(id response))receiveHandler
                    errorHandler:(void (^)(NSError *error))errorHandler;

-(void)totoRequestWithMethodName:(NSString *)method
                      parameters:(id)parameters
                         headers:(NSDictionary*)headers
              useQueryParameters:(BOOL)useQueryParameters
                  receiveHandler:(void (^)(id))receiveHandler
                    errorHandler:(void (^)(NSError *))errorHandler;

-(void)batchRequest:(void(^)())completeHandler;

-(void)queueRequestWithMethodName:(NSString*)method
                       parameters:(id)parameters
                   receiveHandler:(void (^)(id))receiveHandler
                     errorHandler:(void (^)(NSError *))errorHandler;

-(void)queueRequestWithID:(NSString*)requestID
               methodName:(NSString *)method
               parameters:(id)parameters
           receiveHandler:(void (^)(id))receiveHandler
             errorHandler:(void (^)(NSError *))errorHandler;

-(void)clearRequestQueue;

@end
