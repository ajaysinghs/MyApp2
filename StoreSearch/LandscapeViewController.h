//
//  LandscapeViewController.h
//  StoreSearch
//
//  Created by Ajay Singh on 11/8/14.
//  Copyright (c) 2014 Ajay Singh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Search;

@interface LandscapeViewController : UIViewController

@property (nonatomic, strong) Search *search;

- (void)searchResultsReceived;

@end
