//
//  LandscapeViewController.m
//  StoreSearch
//
//  Created by Ajay Singh on 11/8/14.
//  Copyright (c) 2014 Ajay Singh. All rights reserved.
//

#import "LandscapeViewController.h"

#import "SearchResult.h"

#import <AFNetworking/UIButton+AFNetworking.h>

#import "Search.h"

#import "DetailViewController.h"


@interface LandscapeViewController ()<UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;

@end

@implementation LandscapeViewController
{
    BOOL _firstTime;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _firstTime = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"LandscapeBackground"]];
    
    //self.scrollView.contentSize = CGSizeMake(1000, self.scrollView.bounds.size.height);
    
    //for Paging,this will effectively hides the page control when there are no search results (yet)
    self.pageControl.numberOfPages = 0;
                                             
 
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (_firstTime) {
        _firstTime = NO;
        
        if(self.search != nil){
            if (self.search.isLoading) {
                [self showSpinner];
            }
            else if ([self.search.searchResults count] == 0) {
                [self showNothingFoundLabel];
            }
            else {
                [self tileButtons];
            }
        }
    }

}

-(void)showSpinner
{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    spinner.center = CGPointMake(CGRectGetMidX(self.scrollView.bounds) + 0.5f,
                                 CGRectGetMidY(self.scrollView.bounds) + 0.5f);
    
    spinner.tag = 1000;
    [self.view addSubview:spinner];
    [spinner startAnimating];
}

- (void)searchResultsReceived
{
    [self hideSpinner];
    
    if([self.search.searchResults count] == 0){
        [self showNothingFoundLabel];
    }
    else {
    [self tileButtons];
    }
}


-(void)hideSpinner
{
    [[self.view viewWithTag:1000] removeFromSuperview];
}

- (void)showNothingFoundLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = @"Nothing Found";
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    
    [label sizeToFit];
    CGRect rect = label.frame;
    rect.size.width = ceilf(rect.size.width/2.0f) * 2.0f;
    rect.size.height = ceilf(rect.size.height/2.0f) * 2.0f;
    label.frame = rect;
    label.center = CGPointMake(CGRectGetMidX(self.scrollView.bounds), CGRectGetMidY(self.scrollView.bounds));
    [self.view addSubview:label];
}

- (void)tileButtons
{
    int columnsPerPage = 5;
    CGFloat itemWidth = 96.0f;
    CGFloat x = 0.0f;
    CGFloat extraSpace = 0.0f;
    
    CGFloat scrollViewWidth = self.scrollView.bounds.size.width;
    
    if (scrollViewWidth > 480.0f) {
        columnsPerPage = 6;
        itemWidth = 94.0f;
        x = 2.0f;
        extraSpace = 4.0f;
    }
    
    const CGFloat itemHeight = 88.0f;
    const CGFloat buttonWidth = 82.0f;
    const CGFloat buttonHeight = 82.0f;
    const CGFloat marginHorz = (itemWidth - buttonWidth)/2.0f;
    const CGFloat marginVert = (itemHeight - buttonHeight)/2.0f;
    
    int index = 0;
    int row = 0;
    int column = 0;
    
    for (SearchResult *searchResult in self.search.searchResults) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [button setBackgroundImage:[UIImage imageNamed:@"LandscapeButton"] forState:UIControlStateNormal];

        button.frame = CGRectMake(x + marginHorz, 20.0f + row*itemHeight + marginVert, buttonWidth, buttonHeight);
        
        //to show detailview in landscape mode
        button.tag = 2000 + index;
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        
        [self.scrollView addSubview:button];
        
        //to import images on UIButton
        [self downloadImageForSearchResult:searchResult andPlaceOnButton:button];
        
        index++;
        row++;
        if (row == 3) {
            row = 0;
            column++;
            x += itemWidth;
            if (column == columnsPerPage) {
                column = 0;
                x += extraSpace;
            }
        }
    }
    
    
    int tilesPerPage = columnsPerPage * 3;
    int numPages = ceilf([self.search.searchResults count] /(float)tilesPerPage);
    
    self.scrollView.contentSize = CGSizeMake(numPages*scrollViewWidth, self.scrollView.bounds.size.height);
    
    NSLog(@"Number of pages: %d", numPages);
    
    
    //sets the number of dots that the page control displays to the number of pages that you calculated
    self.pageControl.numberOfPages = numPages;
    self.pageControl.currentPage = 0;
}

- (void)buttonPressed:(UIButton *)sender
{
    DetailViewController *controller = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    
    SearchResult *searchResult = self.search.searchResults[sender.tag - 2000];
    controller.searchResult = searchResult;
    [controller presentInParentViewController:self];
    
}



//UIScrollViewDelegate method
- (void)scrollViewDidScroll:(UIScrollView *)theScrollView
{
    CGFloat width = self.scrollView.bounds.size.width;
    int currentPage = (self.scrollView.contentOffset.x + width/2.0f) / width;
    self.pageControl.currentPage = currentPage;
}

//to know when the user taps on the Page Control
- (IBAction)pageChanged:(UIPageControl *)sender
{
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                    self.scrollView.contentOffset = CGPointMake(self.scrollView.bounds.size.width * sender.currentPage, 0);
                     }
                     completion:nil];
    
    
}


//to download images in UIButton
- (void)downloadImageForSearchResult:(SearchResult *)searchResult andPlaceOnButton:(UIButton *)button
{
    NSURL *url = [NSURL URLWithString:searchResult.artworkURL60];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    __weak UIButton *weakButton = button;
    
    [button setImageForState:UIControlStateNormal withURLRequest:request placeholderImage:nil
            success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                UIImage *unscaledImage = [UIImage imageWithCGImage:image.CGImage scale:1.0
                                                       orientation:image.imageOrientation];
                [weakButton setImage:unscaledImage forState:UIControlStateNormal];
            }
     failure:nil];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//dealloc method
- (void)dealloc
{
    NSLog(@"dealloc %@", self);
//    
//    for (UIButton *button in self.scrollView.subviews) {
//        //[button cancelImageRequestOperationForState:UIControlStateNormal];
//    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end











