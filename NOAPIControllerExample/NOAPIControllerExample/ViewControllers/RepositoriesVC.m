//
//  RepositoriesVC.m
//  NOAPIControllerExample
//
//  Created by Alexander Gorbunov on 25/02/16.
//  Copyright © 2016 Noveo. All rights reserved.
//


#import "RepositoriesVC.h"

// Controllers.
#import "GitHubAPIController.h"

// Models.
#import "Repository.h"

// Configuration.
#import "Configuration.h"


static NSString *const kRepositoryCellIdentifier = @"RepositoryCellIdentifier";


@interface RepositoriesVC () <UITableViewDataSource, UITableViewDelegate>

@property (atomic, copy) NSArray *repositories;

@property (nonatomic) IBOutlet UITableView *tableView;

@end


@implementation RepositoriesVC

#pragma mark - VC lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshData];
}

#pragma mark - Private methods

- (void)refreshData
{
    typeof(self) __weak wself = self;
    [self.apiController getRepositoriesForUser:kGitHubUsername withCompletion:^(NSArray *repositories) {
            typeof(wself) __strong sself = wself;
            sself.repositories = repositories;
            [sself.tableView reloadData];
        } failure:^(NSError *error) {
            [self showError:error];
        }];
}

- (void)showError:(NSError *)error
{
    #warning Implement me.
}

#pragma mark - TableView callbacks

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.repositories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kRepositoryCellIdentifier];

    Repository *repo = self.repositories[indexPath.row];
    cell.textLabel.text = repo.title;

    return cell;
}

@end
