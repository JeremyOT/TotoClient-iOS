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
@property (nonatomic,weak) id<TotoServiceAuthenticationDelegate> authenticationDelegate;

@property (weak, nonatomic, readonly) NSString *userID;
@property (weak, nonatomic, readonly) NSString *sessionID;
@property (nonatomic, readonly) NSTimeInterval sessionExpires;
@property (nonatomic, readonly) NSUInteger queuedRequestCount;
@property (nonatomic, strong) NSDictionary *sessionData;
@property (nonatomic, copy) void (^preflightHandler)(NSData *requestBody, NSMutableDictionary *headers);
@property (nonatomic, assign) BOOL signsRequests;
@property (nonatomic, strong, readonly) NSString *contentType;

+(void)setDefaultRequestHeader:(NSString*)value forKey:(NSString*)key;
+(NSString*)defaultRequestHeaderForKey:(NSString*)key;
+(NSDictionary*)allDefaultRequestHeaders;

+(NSData*(^)(id request, NSMutableDictionary *requestHeaders))jsonSerializer;
+(id(^)(NSData *response, NSDictionary *responseHeaders))jsonDeserializer;
+(id(^)(NSData *response, NSDictionary *responseHeaders))jsonDeserializerWithOptions:(NSJSONReadingOptions)options;

+(TotoService*)serviceWithURL:(NSURL*)url;
-(TotoService*)initWithURL:(NSURL*)url;
+(TotoService *)serviceWithURL:(NSURL *)url contentType:(NSString*)contentType requestSerializer:(NSData *(^)(id request, NSMutableDictionary *requestHeaders))requestSerializer;
-(TotoService *)initWithURL:(NSURL *)url contentType:(NSString*)contentType requestSerializer:(NSData *(^)(id request, NSMutableDictionary *requestHeaders))requestSerializer;

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

-(void)setContentType:(NSString *)contentType withSerializer:(NSData* (^)(id request, NSMutableDictionary *requestHeaders))serializer;
-(void)setDeserializer:(id (^)(NSData* response, NSDictionary *responseHeaders))deserializer forContentType:(NSString *)contentType;

@end
