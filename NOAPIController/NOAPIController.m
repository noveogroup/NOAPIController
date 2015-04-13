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

- (void)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    [self getObjectOfType:objectType fromURL:objectURL requestMethod:HTTPRequestMethodGET
        success:success failure:failure];
}

- (void)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    method:(NSString *)httpMethod httpBody:(NSData *)bodyData success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    dispatch_async(self.sendingQueue, ^{
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
                    id object = [self.mapper objectOfType:objectType fromDictionary:rawObject];
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            success(rawObject, object);
                        });
                    }
                });
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (failure) {
                    failure(error, operation.responseObject);
                }
            }];
        [self.requestManager.operationQueue addOperation:operation];
    });
}

- (void)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL POSTData:(NSData *)postData
    success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    [self getObjectOfType:objectType fromURL:objectURL method:@"POST" httpBody:postData
        success:success failure:failure];
}

- (void)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL PUTData:(NSData *)putData
    success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    [self getObjectOfType:objectType fromURL:objectURL method:@"PUT" httpBody:putData
        success:success failure:failure];
}

- (void)postData:(NSData *)postData toURL:(NSString *)objectURL success:(void (^)(id))success
    failure:(void (^)(NSError *error, id response))failure
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

- (void)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL
    requestMethod:(HTTPRequestMethod)method
    success:(void(^)(id rawObject, id resultingObject))success
    failure:(void(^)(NSError *error, id response))failure
{
    dispatch_async(self.sendingQueue, ^{
        void (^successBlock)(AFHTTPRequestOperation *operation, NSDictionary *rawObject) =
            ^(AFHTTPRequestOperation *operation, NSDictionary *rawObject) {
                dispatch_async(self.parsingQueue, ^{
                    id object = [self.mapper objectOfType:objectType fromDictionary:rawObject];
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            success(rawObject, object);
                        });
                    }
                });
            };
        void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) =
            ^(AFHTTPRequestOperation *operation, NSError *error) {
                if (failure) {
                    failure(error, operation.responseObject);
                }
            };

        switch (method) {
            case HTTPRequestMethodGET: {
                [self.requestManager GET:objectURL parameters:nil success:successBlock
                    failure:failureBlock];
                break;
            }
            case HTTPRequestMethodPOST: {
                [self.requestManager POST:objectURL parameters:nil success:successBlock
                    failure:failureBlock];
                break;
            }
            case HTTPRequestMethodDELETE: {
                [self.requestManager DELETE:objectURL parameters:nil success:successBlock
                    failure:failureBlock];
                break;
            }
            case HTTPRequestMethodPUT: {
                [self.requestManager PUT:objectURL parameters:nil success:successBlock
                    failure:failureBlock];
                break;
            }
            default: {
                NSLog(@"Error: Unexpected method for request.");
            }
        }
    });
}

- (void)getObjectsOfType:(Class)objectType fromURL:(NSString *)objectURL
    success:(void(^)(NSArray *, NSArray *))success
    failure:(void(^)(NSError *error, id response))failure
{
    dispatch_async(self.sendingQueue, ^{
        [self.requestManager GET:objectURL parameters:nil
            success:^(AFHTTPRequestOperation *operation, NSArray *rawObjects) {
                dispatch_async(self.parsingQueue, ^{
                    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:rawObjects.count];
                    for (NSDictionary *rawObject in rawObjects) {
                        id object = [self.mapper objectOfType:objectType fromDictionary:rawObject];
                        if (object) {
                            [objects addObject:object];
                        }
                        else {
                            if (failure) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    failure(nil, nil);
                                });
                            }
                        }
                    }
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            success(rawObjects, objects);
                        });
                    }
                });
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (failure) {
                    failure(error, operation.responseObject);
                }
            }];
    });
}

#pragma mark - Private methods

- (void)getObjectOfType:(Class)objectType fromURL:(NSString *)objectURL postBody:(NSData *)bodyData
    boundary:(NSString *)boundary success:(void (^)(id, id))success
    failure:(void (^)(NSError *error, id response))failure
{
    dispatch_async(self.sendingQueue, ^{
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
                     id object = [self.mapper objectOfType:objectType fromDictionary:rawObject];
                     if (success) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             success(rawObject, object);
                         });
                     }
                 });
             }
             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 if (failure) {
                     failure(error, operation.responseObject);
                 }
             }];
        [self.requestManager.operationQueue addOperation:operation];
    });
}

@end
