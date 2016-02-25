//
//  GitHubAPIController.h
//  NOAPIControllerExample
//
//  Created by Alexander Gorbunov on 25/02/16.
//  Copyright © 2016 Noveo. All rights reserved.
//


#import <Foundation/Foundation.h>


@class NOAPITask;
@class Repository;


@interface GitHubAPIController : NSObject

- (NOAPITask *)getRepositoriesForUser:(NSString *)username
    withCompletion:(void (^)(NSArray <Repository *> *repositories))completion failure:(void (^)(NSError *error))failure;

@end
