//
//  MasterViewController.m
//  DataLoader
//
//  Created by Upul Abayagunawardhana on 1/24/15.
//  Copyright (c) 2015 uiroshan. All rights reserved.
//

#import "MasterViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"

static NSString *const kConsumerKey = @"V9NWzLqIqovvwmeizeNz38qhgCaQ7DAJcG5DnM34";

@interface MasterViewController ()

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger totalPages;
@property (nonatomic, assign) NSInteger totalItems;
@property (nonatomic, assign) NSInteger maxPages;

@property (nonatomic, strong) NSMutableArray *photos;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.photos = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadPhotos:self.currentPage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.currentPage == self.maxPages
        || self.currentPage == self.totalPages
        || self.totalItems == self.photos.count) {
        return self.photos.count;
    }
    return self.photos.count + 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.currentPage != self.maxPages && indexPath.row == [self.photos count] - 1 ) {
        [self loadPhotos:++self.currentPage];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    if (indexPath.row == [self.photos count]) {
    
        cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell" forIndexPath:indexPath];
        UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:100];
        [activityIndicator startAnimating];
        
    } else {
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
        NSDictionary *photoItem = self.photos[indexPath.row];
        cell.textLabel.text = [photoItem objectForKey:@"name"];
        if (![[photoItem objectForKey:@"description"] isEqual:[NSNull null]]) {
            cell.detailTextLabel.text = [photoItem objectForKey:@"description"];
        }
        
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[photoItem objectForKey:@"image_url"]]
                          placeholderImage:[UIImage imageNamed:@"placeholder.jpg"]
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                     if (error) {
                                         NSLog(@"Error occured : %@", [error description]);
                                     }
        }];
    }
    
    return cell;
}

- (void)loadPhotos:(NSInteger)page {
    
    NSString *apiURL = [NSString stringWithFormat:@"https://api.500px.com/v1/photos?feature=editors&page=%ld&consumer_key=%@",(long)page,kConsumerKey];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:apiURL]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                if (!error) {
                    
                    NSError *jsonError = nil;
                    NSMutableDictionary *jsonObject = (NSMutableDictionary *)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                    
                    NSLog(@"%@",jsonObject);
                    
                    [self.photos addObjectsFromArray:[jsonObject objectForKey:@"photos"]];
                    
                    self.currentPage = [[jsonObject objectForKey:@"current_page"] integerValue];
                    self.totalPages  = [[jsonObject objectForKey:@"total_pages"] integerValue];
                    self.totalItems  = [[jsonObject objectForKey:@"total_items"] integerValue];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                    });
                }
            }] resume];
}

@end
