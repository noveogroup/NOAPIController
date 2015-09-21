//
//  NOAPITaskRunner.h
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


#import <Foundation/Foundation.h>


@class AbstractAPIController;
@class NOAPIRetriableTask;
@class NOAPITaskRunner;
@protocol NOAPITaskResponse;
@protocol NOAPITask;


typedef void(^FailureBlock)(NSError *error);


@protocol NOAPITaskRunnerDelegate <NSObject>

@optional

// Delegate can create a custom error, for example depending on response data.
- (NSError *)NOAPITaskRunner:(NOAPITaskRunner *)taskRunner
    customErrorForResponse:(id<NOAPITaskResponse>)response
    withError:(NSError *)error;

// This method is called when first attempt of loading taskToRetry has failed.
// Delegate can modify task and generate a a new task, that is required to
// end successfully before retrying the original task.
// Common case is to refresh the access token before retrying a failed task.
- (id<NOAPITask>)NOAPITaskRunner:(NOAPITaskRunner *)taskRunner
    taskForRetryingTask:(NOAPIRetriableTask *)taskToRetry
    success:(void(^)(NOAPIRetriableTask *task))success failure:(FailureBlock)failure;

@end


@interface NOAPITaskRunner : NSObject
@property (nonatomic, strong) AbstractAPIController *apiController;
@property (nonatomic, weak) id<NOAPITaskRunnerDelegate> delegate;
- (void)performTask:(NOAPIRetriableTask *)task;
@end
