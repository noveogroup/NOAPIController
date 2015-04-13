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
#import <AFNetworking/AFNetworking.h>
@import ObjectiveC;


#ifdef DEBUG
    #define LOG(fmt, ...) NSLog((fmt), ##__VA_ARGS__)
    #define DLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __func__, __LINE__, ##__VA_ARGS__)
#else
    #define LOG(...)
    #define DLOG(...)
#endif


@interface AbstractAPIController ()
@property (strong, nonatomic) NSDictionary *fieldsMap;
@property (strong, nonatomic) id transformer;
@property (nonatomic, readwrite) AFHTTPRequestOperationManager *requestManager;
@property (nonatomic) dispatch_queue_t sendingQueue;
@property (nonatomic) dispatch_queue_t parsingQueue;
- (id)objectOfType:(Class)objectType fromDictionary:(NSDictionary *)rawObject;
@end


@implementation AbstractAPIController

#pragma mark - Public methods

- (instancetype)initWithBaseURL:(NSString *)baseAPIURL
    fieldsMap:(NSDictionary *)fieldsMap transformer:(id)transformer
{
    self = [self init];
    if (self) {
        self.fieldsMap = fieldsMap;
        self.transformer = transformer;
        _sendingQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        _parsingQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        self.requestManager = [[AFHTTPRequestOperationManager alloc]
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
                    id object = [self objectOfType:objectType fromDictionary:rawObject];
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
                    id object = [self objectOfType:objectType fromDictionary:rawObject];
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
                DLOG(@"Error: Unexpected method for request.");
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
                        id object = [self objectOfType:objectType fromDictionary:rawObject];
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

- (id)objectOfType:(Class)objectType fromDictionary:(NSDictionary *)rawObject
{
    id objectTransformer = self.fieldsMap[NSStringFromClass(objectType)];
    id (*transform)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;

    // Use external parser method
    if ([objectTransformer isKindOfClass:[NSString class]]) {
        SEL transformerSelector = NSSelectorFromString(objectTransformer);
        return transform(self.transformer, transformerSelector, rawObject);
    }
    // Parse each field
    else {
        if ([rawObject isKindOfClass:objectType]) {
            return rawObject;
        }

        if (![rawObject isKindOfClass:[NSDictionary class]]) {
            return nil;
        }

        if (!objectTransformer) {
            return nil;
        }

        id object = [[objectType alloc] init];
        NSDictionary *fields = objectTransformer;
        
        for (NSString *fieldKey in fields.allKeys) {
            NSDictionary *fieldDescription = fields[fieldKey];

            NSString *objectKey = fieldDescription[@"key"];
            if (!objectKey) {
                objectKey = fieldKey;
            }
            
            NSString *arrayItemClassName = fields[fieldKey][@"arrayOf"];
            NSString *dictionaryItemClassName = fields[fieldKey][@"dictionaryOf"];
            NSString *typeTransformer = fieldDescription[@"transformer"];
            NSString *classOfObject = fieldDescription[@"kindOf"];
            NSString *typeOfField = fieldDescription[@"type"];

            // Parse array of sub-objects.
            if (arrayItemClassName) {
                NSArray *innerArray = rawObject[fieldKey];
                if ([innerArray isKindOfClass:[NSArray class]]) {
                    NSMutableArray *arrayOfItems = [NSMutableArray array];
                    for (NSDictionary *arrayItemDescription in innerArray) {
                        id arrayItem = nil;
                        // Just copy array values (array of NSStrings for example).
                        if ([arrayItemDescription isKindOfClass:NSClassFromString(arrayItemClassName)]) {
                            arrayItem = arrayItemDescription;
                        }
                        // Parse array element.
                        else {
                            arrayItem = [self objectOfType:NSClassFromString(arrayItemClassName)
                                fromDictionary:arrayItemDescription];
                        }
                        if (arrayItem) {
                            [arrayOfItems addObject:arrayItem];
                        }
                        else {
                            LOG(@"Warning: API response for <%@> contains unexpected value: <%@>%@"
                                "for key \"%@\"while in array, while <%@> is expected.", objectType,
                                [arrayItemDescription class], arrayItemDescription, fieldKey,
                                arrayItemClassName);
                        }
                    }
                    [object setValue:arrayOfItems forKey:objectKey];
                }
                else if (innerArray == nil || [innerArray isKindOfClass:[NSNull class]]) {
                    // No value is ok.
                }
                else {
                    LOG(@"Warning: API response for <%@> contains unexpected value: <%@>%@"
                        "for key \"%@\"while an array is expected.", objectType,
                        [innerArray class], innerArray, fieldKey);
                }
            }
            
            // Parse values of dictionary as array.
            else if (dictionaryItemClassName) {
                if ([rawObject[fieldKey] isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *dictOfItems = [NSMutableDictionary dictionary];
                    [rawObject[fieldKey] enumerateKeysAndObjectsUsingBlock:
                        ^(id key, NSDictionary *dictItemDescription, BOOL *stop) {
                            id dictItem = [self objectOfType:NSClassFromString(dictionaryItemClassName)
                                fromDictionary:dictItemDescription];
                            dictOfItems[key] = dictItem;
                        }];
                    [object setValue:dictOfItems forKey:objectKey];
                }
            }
            
            // Parse object that should be transformed.
            else if (typeTransformer) {
                SEL transformerSelector = NSSelectorFromString(typeTransformer);
                id transformedData = transform(self.transformer, transformerSelector,
                    [rawObject valueForKeyPath:fieldKey]);
                [object setValue:transformedData forKey:objectKey];
            }
            
            // Parse object according to its class.
            else if (classOfObject) {
                id innerObject = [self objectOfType:NSClassFromString(classOfObject)
                    fromDictionary:[rawObject valueForKeyPath:fieldKey]];
                if (object) {
                    [object setValue:innerObject forKeyPath:objectKey];
                }
            }
            
            // Check type of the value, don't copy invalid values.
            else if (typeOfField) {
                id innerObject = [rawObject valueForKeyPath:fieldKey];
                if ([innerObject isKindOfClass:NSClassFromString(typeOfField)]) {
                    [object setValue:[rawObject valueForKeyPath:fieldKey] forKey:objectKey];
                }
                else if (innerObject == nil || [innerObject isKindOfClass:[NSNull class]]) {
                    // No value is ok.
                }
                else {
                    LOG(@"Warning: API response for <%@> contains unexpected value: <%@>%@"
                        "for key \"%@\"while an instance of <%@> is expected.", objectType,
                        [innerObject class], innerObject, fieldKey, typeOfField);
                }
            }
            
            // Plain value copy.
            else {
                id innerObject = [rawObject valueForKeyPath:fieldKey];
                if (innerObject) {
                    [object setValue:[rawObject valueForKeyPath:fieldKey] forKey:objectKey];
                }
            }
        }
        return object;
    }
}

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
                     id object = [self objectOfType:objectType fromDictionary:rawObject];
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
