//
//  SearchResultCell.h
//  StoreSearch
//
//  Created by Ajay Singh on 10/26/14.
//  Copyright (c) 2014 Ajay Singh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchResult;

@interface SearchResultCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic, weak) IBOutlet UILabel *artistNameLabel;

@property (nonatomic, weak) IBOutlet UIImageView *artworkImageView;

- (void)configureForSearchResult:(SearchResult *)searchResult;

@end
