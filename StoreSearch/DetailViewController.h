//
//  DetailViewController.h
//  StoreSearch
//
//  Created by Ajay Singh on 11/2/14.
//  Copyright (c) 2014 Ajay Singh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchResult;

@interface DetailViewController : UIViewController

@property (nonatomic, strong) SearchResult *searchResult;

- (void)presentInParentViewController:(UIViewController *)parentViewController;

- (void)dismissFromParentViewController;

@end
