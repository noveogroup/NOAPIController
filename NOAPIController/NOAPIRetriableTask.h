//
//  NOAPIRetriableTask.h
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
#import "NOAPIController.h"
#import "NOAPITaskProtocol.h"


@protocol NOAPITaskResponse;


typedef void(^FailureBlock)(NSError *error);
typedef void(^ResponseBlock)(id<NOAPITaskResponse> response);


@interface NOAPIRetriableTask : NSObject <NOAPITask>
@property (nonatomic) HTTPRequestMethod method;
@property (nonatomic, copy) NSString *URL;
@property (nonatomic, copy) NSDictionary *URIParameters;
@property (nonatomic, copy) NSData *bodyData;
@property (nonatomic) Class responseClass;
@property (nonatomic, copy) ResponseBlock success;
@property (nonatomic, copy) FailureBlock failure;
@property (nonatomic) BOOL canRetry;
@property (nonatomic) BOOL secondTry;
@property (atomic, readwrite) BOOL cancelled;
@property (nonatomic) id<NOAPITask> currentTask;
@end
