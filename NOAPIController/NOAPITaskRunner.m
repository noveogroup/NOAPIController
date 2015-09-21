//
//  NOAPITaskRunner.m
//  NOAPIController
//
//  Created by Alexander Gorbunov on 21/09/15.
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


#import "NOAPITaskRunner.h"
#import "NOAPIRetriableTask.h"
#import "NOAPIController.h"


typedef void (^ExtendedFailureBlock)(NSError *error, id response);


@implementation NOAPITaskRunner

// This function builds @"relative/url/path?with=many&many=parameters"
// from
// @"relative/url/path"
// and
// @{with: many, many: parameters}
static NSString *urlWithParameters(NSString *resource, NSDictionary *parameters)
{
    NSMutableArray *pairs = [[NSMutableArray alloc] initWithCapacity:parameters.count];
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSObject *object, BOOL *stop) {
            if ([object isKindOfClass:[NSArray class]]) {
                for (NSString *value in (NSArray *)object) {
                    [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
                }
            }
            else {
                [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, object]];
            }
        }];

    NSString *parametersString = [pairs componentsJoinedByString:@"&"];
    if (parametersString.length == 0) {
        return resource;
    }
    else {
        return [NSString stringWithFormat:@"%@?%@", resource, parametersString];
    }
}

- (ExtendedFailureBlock)safeFail:(FailureBlock)failure
{
    return ^(NSError *error, id<NOAPITaskResponse> response) {
        // Client can generate more exact error while getting general networking error.
        if ([self.delegate respondsToSelector:@selector(NOAPITaskRunner:customErrorForResponse:withError:)]) {
            error = [self.delegate NOAPITaskRunner:self customErrorForResponse:response withError:error];
        }

        if (failure) {
            failure(error);
        }
        else {
            NSLog(@"An error occured while making API request: %@", error);
        }
    };
}

- (void)performTask:(NOAPIRetriableTask *)task
{
    NSAssert(task.success, @"Success block can not be nil.");
    NSAssert(task.URL, @"URL can not be nil.");
    NSAssert(task.responseClass, @"Response class must be defined.");
    NSAssert(task.method != HTTPRequestMethodUnknown, @"Task method must be defined.");
    
    if (task.cancelled) {
        return;
    }
    
    NSString *fullURL = urlWithParameters(task.URL, task.URIParameters);
    
    void (^success)(id rawObject, id<NOAPITaskResponse> response) =
        ^(id rawObject, id<NOAPITaskResponse> response) {
            if (task.cancelled) {
                return;
            }
            
            NSError *responseError = nil;
            if ([self.delegate respondsToSelector:@selector(NOAPITaskRunner:customErrorForResponse:withError:)]) {
                responseError = [self.delegate NOAPITaskRunner:self customErrorForResponse:response withError:nil];
            }
            
            if (responseError) {
                [self safeFail:task.failure](responseError, response);
            }
            else {
                task.success(response);
            }
        };

    void (^failure)(NSError *error, id<NOAPITaskResponse> response) =
        ^(NSError *error, id<NOAPITaskResponse> response) {
            if (task.cancelled) {
                return;
            }
            
            if (!task.canRetry && task.secondTry) {
                [self safeFail:task.failure](error, response);
                return;
            }
            
            if ([self.delegate respondsToSelector:@selector(NOAPITaskRunner:taskForRetryingTask:success:failure:)]) {
                task.currentTask = [self.delegate NOAPITaskRunner:self taskForRetryingTask:task
                    success:^(NOAPIRetriableTask *secondTryTask) {
                        secondTryTask.secondTry = YES;
                        [self performTask:secondTryTask];
                    }
                    failure:task.failure];
            }
            else {
                task.secondTry = YES;
                [self performTask:task];
            }
        };

    if (task.method == HTTPRequestMethodGET || task.method == HTTPRequestMethodDELETE) {
        task.currentTask = [self.apiController getObjectOfType:task.responseClass fromURL:fullURL
            requestMethod:task.method success:success failure:failure];
    }
    else if (task.method == HTTPRequestMethodPOST) {
        task.currentTask = [self.apiController getObjectOfType:task.responseClass fromURL:fullURL
            POSTData:task.bodyData success:success failure:failure];
    }
    else if (task.method == HTTPRequestMethodPUT) {
        task.currentTask = [self.apiController getObjectOfType:task.responseClass fromURL:fullURL
            PUTData:task.bodyData success:success failure:failure];
    }
}

@end
