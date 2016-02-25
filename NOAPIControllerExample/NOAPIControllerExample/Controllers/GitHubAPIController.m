//
//  GitHubAPIController.m
//  NOAPIControllerExample
//
//  Created by Alexander Gorbunov on 25/02/16.
//  Copyright © 2016 Noveo. All rights reserved.
//


#import "GitHubAPIController.h"

// Controllers.
#import "GitHubAPIMapper.h"

// Models.
#import "Repository.h"

// Configuration.
#import "Configuration.h"

// Libraries.
#import <NOAPIController.h>


@interface GitHubAPIController ()

@property (nonatomic) AbstractAPIController *apiController;
@property (nonatomic) GitHubAPIMapper *mapper;

@end


@implementation GitHubAPIController

#pragma mark - Object lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mapper = [[GitHubAPIMapper alloc] init];
        _apiController = [[AbstractAPIController alloc] initWithBaseURL:kBaseGitHubAPIURL
            fieldsMap:_mapper.map transformer:_mapper];
    }
    return self;
}

#pragma mark - Public methods

- (NOAPITask *)getRepositoriesForUser:(NSString *)username
    withCompletion:(void (^)(NSArray <Repository *> *))completion failure:(void (^)(NSError *))failure
{
    Repository *repo1 = [[Repository alloc] init];
    repo1.title = @"repo 1";

    Repository *repo2 = [[Repository alloc] init];
    repo2.title = @"repo 2";
    
    completion(@[repo1, repo2]);

    return nil;
}

@end
