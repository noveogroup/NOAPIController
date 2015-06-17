//
//  NOAPIController.h
//  NOAPIController
//
//  Created by Alexander Gorbunov on 09/04/15.
//  Copyright (c) 2015 Noveo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, HTTPRequestMethod) {
    HTTPRequestMethodUnknown = 0,
    HTTPRequestMethodGET,
    HTTPRequestMethodPOST,
    HTTPRequestMethodPUT,
    HTTPRequestMethodDELETE
};


@class AFHTTPRequestOperationManager;

@protocol NOAPITask;


/*
    Format/example of fieldsMap:

    @"ClassName": @{
        @"api_key": @{
            @"key": @"keypath",
            @"type": @"NSString",
            @"transformer": @"transformer method name (api_type -> property_type)"
        },
        @"api_key": @{
            @"key": @"keypath",
            @"kindOf": @"MyType"
        },
        @"api_key": @{
            @"key": @"keypath",
            @"arrayOf": NSStringFromClass([MyClass class])
        },
        @"api_key": @{
            @"key": @"keypath",
            @"dictionaryOf": NSStringFromClass([MyClass class])
        }
    },
    @"ClassName": @"transformer method name (dictionary -> object_type)",
*/


@interface AbstractAPIController : NSObject
@property (nonatomic, readonly) AFHTTPRequestOperationManager *requestManager;

- (instancetype)initWithBaseURL:(NSString *)baseAPIURL fieldsMap:(NSDictionary *)fieldsMap
    transformer:(id)transformer;

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    success:(void(^)(id rawObject, id resultingObject))success
    failure:(void(^)(NSError *error, id response))failure;

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    method:(NSString *)httpMethod httpBody:(NSData *)bodyData success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure;

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    POSTData:(NSData *)postData success:(void(^)(id rawObject, id resultingObject))success
    failure:(void(^)(NSError *error, id response))failure;

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    PUTData:(NSData *)putData success:(void(^)(id rawObject, id resultingObject))success
    failure:(void(^)(NSError *error, id response))failure;

- (void)postData:(NSData *)postData toURL:(NSString *)objectURL
    success:(void (^)(id))success failure:(void (^)(NSError *error, id response))failure;

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    requestMethod:(HTTPRequestMethod)method
    success:(void(^)(id rawObject, id resultingObject))success
    failure:(void(^)(NSError *error, id response))failure;

- (id<NOAPITask>)getObjectsOfType:(Class)objectType fromURL:(NSString *)objectURL
    success:(void(^)(NSArray *rawObjects, NSArray *resultingObjects))success
    failure:(void(^)(NSError *error, id response))failure;

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    postBody:(NSData *)bodyData boundary:(NSString *)boundary success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure;

@end
