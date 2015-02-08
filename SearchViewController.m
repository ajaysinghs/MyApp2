//
//  SearchViewController.m
//  StoreSearch
//
//  Created by Ajay Singh on 10/21/14.
//  Copyright (c) 2014 Ajay Singh. All rights reserved.
//

#import "SearchViewController.h"

#import "SearchResult.h"

#import "SearchResultCell.h"

#import <AFNetworking/AFNetworking.h>

#import "DetailViewController.h"

#import "LandscapeViewController.h"

#import "Search.h"




static NSString * const SearchResultCellIdentifier = @"SearchResultCell";

static NSString * const NothingFoundCellIdentifier = @"NothingFoundCell";

static NSString * const LoadingCellIdentifier = @"LoadingCell";



@interface SearchViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;



@end

@implementation SearchViewController


{
//    NSMutableArray *_searchResults;
//    
//    BOOL _isLoading;
//    
//    NSOperationQueue *_queue;
    
    Search *_search;
    
    LandscapeViewController *_landscapeViewController;
    
    UIStatusBarStyle _statusBarStyle;
    
}


//Intializing NSOperationQueue
//-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nil];
//    
//    if (self) {
//        _queue = [[NSOperationQueue alloc] init];
//    }
//    return self;
//}




- (void)viewDidLoad {
    [super viewDidLoad];
    
    // first row will always be visible, and when you scroll the table view the cells still go under the search bar.
    self.tableView.contentInset =  UIEdgeInsetsMake(108, 0, 0, 0);
    
    
    //nib for Search Result cell
    UINib *cellnib = [UINib nibWithNibName:SearchResultCellIdentifier bundle:nil];
    [self.tableView registerNib:cellnib forCellReuseIdentifier:SearchResultCellIdentifier];
    
    self.tableView.rowHeight = 80;
    
    
    //nib for Nothing found Cell
    cellnib = [UINib nibWithNibName:NothingFoundCellIdentifier bundle:nil];
    [self.tableView registerNib:cellnib forCellReuseIdentifier:NothingFoundCellIdentifier];
    
    
    //nib for Activity Indicator
    cellnib = [UINib nibWithNibName:LoadingCellIdentifier bundle:nil];
    [self.tableView registerNib:cellnib forCellReuseIdentifier:LoadingCellIdentifier];
    
    _statusBarStyle = UIStatusBarStyleDefault;
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
    [self.searchBar becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
 
}



#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    
    if (_search == nil) {
        return 0; // Not searched yet
    }
    else if (_search.isLoading) {
        return 1; // Loading...
     }
    else if ([_search.searchResults count] == 0) {
       return 1; // Nothing Found
     }
   else {
        return [_search.searchResults count];
    }
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_search.isLoading) {
        UITableViewCell *cell = [tableView  dequeueReusableCellWithIdentifier:LoadingCellIdentifier forIndexPath:indexPath];
       
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:100];
        
        [spinner startAnimating];
        
        return cell;
    }
    
    
    else if ([_search.searchResults count] == 0) {
        return [tableView dequeueReusableCellWithIdentifier:NothingFoundCellIdentifier forIndexPath:indexPath];
    }
    else {
        SearchResultCell *cell = (SearchResultCell *)[tableView dequeueReusableCellWithIdentifier:SearchResultCellIdentifier forIndexPath:indexPath];
        
        SearchResult *searchResult = _search.searchResults[indexPath.row];
        
        [cell configureForSearchResult:searchResult];

    return cell;
    }
    
}



#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self.searchBar resignFirstResponder];
    
    
    // to set the properties of Detail View Controller
    SearchResult *searchResult = _search.searchResults[indexPath.row];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DetailViewController *controller = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    controller.searchResult = searchResult;
    
    [controller presentInParentViewController:self];
    
    self.detailViewController = controller;
    }
    else {
        self.detailViewController.searchResult = searchResult;
    }
    
}

//    //Before you add its view to the window,  resize it to the proper dimensions (e.g After you instantiate the DetailViewController it always has a view that is 568 points high, even on a 3.5-inch device.)
//    controller.view.frame = self.view.frame;
//    //Using the view controller containment APIs to embed the DetailViewController “inside” the SearchViewController.
//    [self.view addSubview:controller.view];
//    [self addChildViewController:controller];
//    [controller didMoveToParentViewController:self];
    
    



- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_search.searchResults count] == 0 || _search.isLoading) {
        return nil;
    }
    else {
        return indexPath;
    }
    
}





#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self performSearch];
}



-(void)performSearch
{
    _search = [[Search alloc] init];
    NSLog(@"allocated %@", _search);
    
    [_search performSearchForText:self.searchBar.text
                         category:self.segmentedControl.selectedSegmentIndex
                            completion:^(BOOL success) {
                                if (!success) {
                                    [self showNetworkError];
                                }
                                [_landscapeViewController searchResultsReceived];
                                [self.tableView reloadData];
                            }];
    
    [self.tableView reloadData];
    [self.searchBar resignFirstResponder];
}


//    if ([self.searchBar.text length] > 0) {
//    [self.searchBar resignFirstResponder];
//        
//        //cancelAllOperations you make sure that no old searches can ever get in the way of the new search.
//        [_queue cancelAllOperations];
//    
//        _isLoading = YES;
//        [self.tableView reloadData];
//        
//        _searchResults = [[NSMutableArray alloc] initWithCapacity:10];
//        
//        
//        //To make the web service requests asynchronous, putting the networking part into a block and then place that block on a medium priority queue
//        
//        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//        
//        dispatch_async(queue, ^{
//            
//            NSURL *url = [self urlWithSearchText:self.searchBar.text category:self.segmentedControl.selectedSegmentIndex];
//            
//            
//            //Implementing AFNetworking Library
//            
//            NSURLRequest *request = [NSURLRequest requestWithURL:url];
//            
//            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
//            
//            operation.responseSerializer = [AFJSONResponseSerializer serializer];
//            
//            [operation setCompletionBlockWithSuccess:^
//                  (AFHTTPRequestOperation *operation, id responseObject) {
//                      [self parseDictionary:responseObject];
//                      [_searchResults sortUsingSelector:@selector(compareName:)];
//                      _isLoading = NO;
//                      [self.tableView reloadData];
//                 //NSLog(@"Success! %@", responseObject);
//               }
//                 failure:^(AFHTTPRequestOperation *operation, NSError *error){
//                      //to prevent the app from showing an error message if user cancel the searching
//                     if (operation.isCancelled) {
//                         return;
//                     }
//                     [self showNetworkError];
//                     _isLoading = NO;
//                     [self.tableView reloadData];
//                  NSLog(@"Failure! %@", error);
//                 }];
//            
//            [_queue addOperation:operation];
    
            
            
            
            //NSString *jsonString = [self performStoreRequestWithURL:url];
            
            //If something goes wrong, you call the showNetworkError method to show an alert box
//            if (jsonString == nil) {
//                 // putting Alert message in main tread via main queue since it will be on UI
//                dispatch_async(dispatch_get_main_queue(), ^{
//                
//                [self showNetworkError];
//                });
//                return;
//            }
//        
//            NSDictionary *dictionary = [self parseJSON:jsonString];
//            
//            //If something goes wrong, you call the showNetworkError method to show an alert box
//            if (dictionary == nil) {
//                // putting Alert message in main tread via main queue since it will be on UI
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self showNetworkError];
//                    });
//                return;
//              }
//        
//        
//            [self parseDictionary:dictionary];
            
            //for sorting
//            [_searchResults sortUsingSelector:@selector(compareName:)];
//            
//            NSLog(@"DONE!");

       
//        //Putting reload tableview in main tread via main queue since it will be in UI
//        dispatch_async(dispatch_get_main_queue(), ^{
//            _isLoading = NO;
//            [self.tableView reloadData];
//        });
//    }
//}
    





//- (NSString *)performStoreRequestWithURL:(NSURL *)url
//{
//    NSError *error;
//    
//    NSString *resultString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
//    
//    if (resultString == nil) {
//        
//        NSLog(@"Download Error: %@", error);
//        
//        return nil;
//    }
//    return resultString;
//}


//- (NSDictionary *)parseJSON:(NSString *)jsonString
//{
//    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//    
//    NSError *error;
//    
//    id resultObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//    
//
//    // to check that the object returned by NSJSONSerialization is truly an NSDictionary
//        if (![resultObject isKindOfClass:[NSDictionary class]]) {
//            
//            NSLog(@"JSON Error: Expected dictionary");
//            
//            return nil;
//        }
//    return resultObject;
//}








- (void)showNetworkError
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Whoops..."
                              message:@"There was an error reading from the iTunes Store. Please try again."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
}



-(UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}


- (IBAction)segmentChanged:(UISegmentedControl *)sender
{
   if (_search != nil) {
       [self performSearch];
    }
}


//change to landscape mode
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        
       [self hideLandscapeViewWithDuration:duration];
    }
    else{
        [self showLandscapeViewWithDuration:duration];
    }
    }
}


- (void)showLandscapeViewWithDuration:(NSTimeInterval)duration
{
    if (_landscapeViewController == nil) {
        _landscapeViewController = [[LandscapeViewController alloc] initWithNibName:@"LandscapeViewController"  bundle:nil];
        
        //to assign array objects to LandscapeViewController
        _landscapeViewController.search = _search;
        
        _landscapeViewController.view.frame = self.view.bounds;
        
        _landscapeViewController.view.alpha = 0.0f;
       
       
        [self.view addSubview:_landscapeViewController.view];
        [self addChildViewController:_landscapeViewController];

        
        [UIView animateWithDuration:duration animations:^{
            _landscapeViewController.view.alpha = 1.0f;
            // for barstyle color change
            _statusBarStyle = UIStatusBarStyleLightContent;
            [self setNeedsStatusBarAppearanceUpdate];
            
        } completion:^(BOOL finished){
            [_landscapeViewController didMoveToParentViewController:self];
        }];
        
        [self.searchBar resignFirstResponder];
        
        [self.detailViewController dismissFromParentViewControllerWithAnimationType:DetailViewControllerAnimationTypeFade];
        
    }
}

    
    
    
- (void)hideLandscapeViewWithDuration:(NSTimeInterval)duration
{
    if (_landscapeViewController != nil) {
        [_landscapeViewController willMoveToParentViewController:nil];
        
        [UIView animateWithDuration:duration animations:^{
            _landscapeViewController.view.alpha = 0.0f;
            
            //// for barstyle color change
            _statusBarStyle = UIStatusBarStyleDefault;
            [self setNeedsStatusBarAppearanceUpdate];
            
        } completion:^(BOOL finished){
            [_landscapeViewController.view removeFromSuperview];
            [_landscapeViewController removeFromParentViewController];
            _landscapeViewController = nil;
            
        }];
       
    }
}


//to determine what color to make the status bar when mode changed from portait to landscape

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return _statusBarStyle;
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









