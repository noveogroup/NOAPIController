//
//  RepositoriesVC.h
//  NOAPIControllerExample
//
//  Created by Alexander Gorbunov on 25/02/16.
//  Copyright © 2016 Noveo. All rights reserved.
//


#import <UIKit/UIKit.h>


@class GitHubAPIController;


@interface RepositoriesVC : UIViewController

@property (nonatomic) IBOutlet GitHubAPIController *apiController;

@end
