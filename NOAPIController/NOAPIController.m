//
//  NOAPIController.m
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


#import "NOAPIController.h"
#import "NOAPIMapper.h"
#import "NOAPITask.h"
#import <AFNetworking/AFNetworking.h>

@interface AbstractAPIController ()
@property (nonatomic) NOAPIMapper *mapper;
@property (nonatomic) AFHTTPRequestOperationManager *requestManager;
@property (nonatomic) dispatch_queue_t sendingQueue;
@property (nonatomic) dispatch_queue_t parsingQueue;
@end


@implementation AbstractAPIController

#pragma mark - Public methods

- (instancetype)initWithBaseURL:(NSString *)baseAPIURL
    fieldsMap:(NSDictionary *)fieldsMap transformer:(id)transformer
{
    self = [self init];
    if (self) {
        _mapper = [[NOAPIMapper alloc] initWithFieldsMap:fieldsMap transformer:transformer];
        _sendingQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        _parsingQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        _requestManager = [[AFHTTPRequestOperationManager alloc]
            initWithBaseURL:[NSURL URLWithString:baseAPIURL]];
    }
    return self;
}

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    return [self getObjectOfType:objectType fromURL:objectURL requestMethod:HTTPRequestMethodGET
        success:success failure:failure];
}

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    method:(NSString *)httpMethod httpBody:(NSData *)bodyData success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    NOAPITask *apiTask = [[NOAPITask alloc] init];
    apiTask.successBlock = success;
    apiTask.failureBlock = failure;

    dispatch_async(self.sendingQueue, ^{
        if (apiTask.cancelled) {
            return;
        }
        NSString *urlString = [[NSURL URLWithString:objectURL relativeToURL:self.requestManager.baseURL]
            absoluteString];

        NSMutableURLRequest *request = [self.requestManager.requestSerializer
            requestWithMethod:httpMethod URLString:urlString parameters:nil error:nil];

        request.HTTPBody = bodyData;

        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        AFHTTPRequestOperation *operation = [self.requestManager HTTPRequestOperationWithRequest:request
            success:^(AFHTTPRequestOperation *operation, id rawObject) {
                dispatch_async(self.parsingQueue, ^{
                    if (apiTask.cancelled) {
                        return;
                    }
                    id object = [self.mapper objectOfType:objectType fromDictionary:rawObject];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!apiTask.cancelled && apiTask.successBlock) {
                            apiTask.successBlock(rawObject, object);
                        }
                    });
                });
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (!apiTask.cancelled && apiTask.failureBlock) {
                    apiTask.failureBlock(error, operation.responseObject);
                }
            }];
        [self.requestManager.operationQueue addOperation:operation];
    });
    return apiTask;
}

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    POSTData:(NSData *)postData success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    return [self getObjectOfType:objectType fromURL:objectURL method:@"POST" httpBody:postData
        success:success failure:failure];
}

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    PUTData:(NSData *)putData success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    return [self getObjectOfType:objectType fromURL:objectURL method:@"PUT" httpBody:putData
        success:success failure:failure];
}

- (void)postData:(NSData *)postData toURL:(NSString *)objectURL
    success:(void (^)(id))success failure:(void (^)(NSError *error, id response))failure
{
    dispatch_async(self.sendingQueue, ^{
        NSString *urlString = [[NSURL URLWithString:objectURL relativeToURL:self.requestManager.baseURL]
            absoluteString];

        NSMutableURLRequest *request = [self.requestManager.requestSerializer requestWithMethod:@"POST"
            URLString:urlString parameters:nil error:nil];

        request.HTTPBody = postData;

        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        AFHTTPRequestOperation *operation = [self.requestManager HTTPRequestOperationWithRequest:request
            success:^(AFHTTPRequestOperation *operation, id rawObject) {
                if (success) {
                    success(rawObject);
                }
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (failure) {
                    failure(error, operation.responseObject);
                }
            }];
        [self.requestManager.operationQueue addOperation:operation];
    });
}

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    requestMethod:(HTTPRequestMethod)method
    success:(void(^)(id rawObject, id resultingObject))success
    failure:(void(^)(NSError *error, id response))failure
{
    NOAPITask *apiTask = [[NOAPITask alloc] init];
    apiTask.successBlock = success;
    apiTask.failureBlock = failure;

    dispatch_async(self.sendingQueue, ^{
        if (apiTask.cancelled) {
            return;
        }
        void (^successBlock)(AFHTTPRequestOperation *operation, NSDictionary *rawObject) =
            ^(AFHTTPRequestOperation *operation, NSDictionary *rawObject) {
                dispatch_async(self.parsingQueue, ^{
                    if (apiTask.cancelled) {
                        return;
                    }
                    id object = [self.mapper objectOfType:objectType fromDictionary:rawObject];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!apiTask.cancelled && apiTask.successBlock) {
                            apiTask.successBlock(rawObject, object);
                        }
                    });
                });
            };
        void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) =
            ^(AFHTTPRequestOperation *operation, NSError *error) {
                if (!apiTask.cancelled && apiTask.failureBlock) {
                    apiTask.failureBlock(error, operation.responseObject);
                }
            };

        switch (method) {
            case HTTPRequestMethodGET: {
                apiTask.operation = [self.requestManager GET:objectURL parameters:nil
                    success:successBlock failure:failureBlock];
                break;
            }
            case HTTPRequestMethodPOST: {
                apiTask.operation = [self.requestManager POST:objectURL parameters:nil
                    success:successBlock failure:failureBlock];
                break;
            }
            case HTTPRequestMethodDELETE: {
                apiTask.operation = [self.requestManager DELETE:objectURL parameters:nil
                    success:successBlock failure:failureBlock];
                break;
            }
            case HTTPRequestMethodPUT: {
                apiTask.operation = [self.requestManager PUT:objectURL parameters:nil
                    success:successBlock failure:failureBlock];
                break;
            }
            default: {
                NSLog(@"Error: Unexpected method for request.");
            }
        }
    });
    return apiTask;
}

- (id<NOAPITask>)getObjectsOfType:(Class)objectType fromURL:(NSString *)objectURL
    success:(void(^)(NSArray *, NSArray *))success
    failure:(void(^)(NSError *error, id response))failure
{
    NOAPITask *apiTask = [[NOAPITask alloc] init];
    apiTask.successBlock = success;
    apiTask.failureBlock = failure;

    dispatch_async(self.sendingQueue, ^{
        if (apiTask.cancelled) {
            return;
        }
        [self.requestManager GET:objectURL parameters:nil
            success:^(AFHTTPRequestOperation *operation, NSArray *rawObjects) {
                dispatch_async(self.parsingQueue, ^{
                    if (apiTask.cancelled) {
                        return;
                    }
                    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:rawObjects.count];
                    for (NSDictionary *rawObject in rawObjects) {
                        id object = [self.mapper objectOfType:objectType fromDictionary:rawObject];
                        if (object) {
                            [objects addObject:object];
                        }
                        else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (!apiTask.cancelled && apiTask.failureBlock) {
                                    apiTask.failureBlock(nil, nil);
                                }
                            });
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!apiTask.cancelled && apiTask.successBlock) {
                            apiTask.successBlock(rawObjects, objects);
                        }
                    });
                });
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (!apiTask.cancelled && apiTask.failureBlock) {
                    apiTask.failureBlock(error, operation.responseObject);
                }
            }];
    });
    return apiTask;
}

#pragma mark - Private methods

- (id<NOAPITask>)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    postBody:(NSData *)bodyData boundary:(NSString *)boundary success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    NOAPITask *apiTask = [[NOAPITask alloc] init];
    apiTask.successBlock = success;
    apiTask.failureBlock = failure;

    dispatch_async(self.sendingQueue, ^{
        if (apiTask.cancelled) {
            return;
        }
        NSString *urlString = [[NSURL URLWithString:objectURL relativeToURL:self.requestManager.baseURL]
            absoluteString];

        NSMutableURLRequest *request = [self.requestManager.requestSerializer
            requestWithMethod:@"POST" URLString:urlString parameters:nil error:nil];

        request.HTTPBody = bodyData;

        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
            forHTTPHeaderField:@"Content-Type"];

        AFHTTPRequestOperation *operation = [self.requestManager HTTPRequestOperationWithRequest:request
            success:^(AFHTTPRequestOperation *operation, id rawObject) {
                dispatch_async(self.parsingQueue, ^{
                    if (apiTask.cancelled) {
                        return;
                    }
                    id object = [self.mapper objectOfType:objectType fromDictionary:rawObject];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!apiTask.cancelled && apiTask.successBlock) {
                            apiTask.successBlock(rawObject, object);
                        }
                    });
                 });
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (!apiTask.cancelled && apiTask.failureBlock) {
                    apiTask.failureBlock(error, operation.responseObject);
                }
            }];
        [self.requestManager.operationQueue addOperation:operation];
    });
    return apiTask;
}

@end
