//
//  SearchResultCell.m
//  StoreSearch
//
//  Created by Ajay Singh on 10/26/14.
//  Copyright (c) 2014 Ajay Singh. All rights reserved.
//

#import "SearchResultCell.h"


@implementation SearchResultCell


// row selection to have the same bluish-green tint.

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    UIView *selectedView = [[UIView alloc] initWithFrame:CGRectZero];
    
    selectedView.backgroundColor = [UIColor colorWithRed:20/255.0f green:160/255.0f blue:160/255.0f alpha:0.5f];
    
    self.selectedBackgroundView = selectedView;
}

@end
