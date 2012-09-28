//
//  MVSwitchViewController.m
//  MusicPlayer
//
//  Created by Bill on 12-8-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MVSwitchViewController.h"
#import "MVCell.h"
#import "MVInformation.h"

#import "SearchBarCell.h"
#import "Constents.h"
#import "DFLyricsMusicPlayer.h"
#import "DFOnlinePlayer.h"

@implementation MVSwitchViewController

@synthesize firstLoaded;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self.view setFrame:CGRectMake(0, 0, 320, 480)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    displaySearch=NO;
    
    if(!mvTableView)mvTableView=[[PullToRefreshTableView alloc]initWithFrame:CGRectMake(0, 44, 320, 367) style:UITableViewStylePlain];
    
    mvTableView.delegate=self;
    mvTableView.dataSource=self;
    
    [mvTableView addFooterRefreshViewWithDelegate:self];
    
    [self.view insertSubview:mvTableView atIndex:0];
    
    lastSearchString=[NSString string];
    
    firstLoaded=NO;
    
    [mvTableView.footerRefreshView setStringWithPullToRefreshString:@"上拉获取更多" ReleaseToRefreshString:@"松开获取更多" LoadingString:@"正在加载"];
}

-(void)loadHotMVData{
    if(!hotMVResult.tableViewArray)hotMVResult.tableViewArray=[[NSMutableArray alloc]init];
    hotMVResult.nowPageAt=1;
    HotMVGetter *getter=[[[HotMVGetter alloc]init]autorelease];
    getter.delegate=self;
    [getter getHotMVWithPage:1];
    firstLoaded=YES;
    [SVProgressHUD showWithStatus:@"Getting Data..."];
    [mvTableView setUserInteractionEnabled:NO];
}

-(void)downloadFinishedWithResult:(struct mvInformation)result AndKey:(NSString *)key{
    static BOOL firstGetted=NO;
    if([key isEqualToString:@"hotMVXML"]){
        for(MVInformation *inf in result.information){
            [hotMVResult.tableViewArray addObject:inf];
        }
        hotMVResult.pagesCount=result.pagesCount;
        NSLog(@"%i",hotMVResult.pagesCount);
        [mvTableView reloadData];
        [mvTableView setFooterRefreshViewToCorrentFrame];
        if(gettingMore==YES){
            [self performSelector:@selector(doneLoadingTableViewData)];
        }
        if(!firstGetted){
            [mvTableView setUserInteractionEnabled:YES];
            [SVProgressHUD showSuccessWithStatus:@"Finished"];
        }
        firstGetted=YES;
    }else if([key isEqualToString:@"searchXML"]){
        [searchResult.tableViewArray removeAllObjects];
        for(MVInformation *inf in result.information){
            [searchResult.tableViewArray addObject:inf];
        }
        searchResult.pagesCount=result.pagesCount;
        [mvTableView reloadData];
        [mvTableView setFooterRefreshViewToCorrentFrame];
        [mvTableView setUserInteractionEnabled:YES];
        [SVProgressHUD showSuccessWithStatus:@"Finished"];
    }else if([key isEqualToString:@"searchMoreXML"]){
        for(MVInformation *inf in result.information){
            [searchResult.tableViewArray addObject:inf];
        }
        [mvTableView reloadData];
        [mvTableView setFooterRefreshViewToCorrentFrame];
        [self performSelector:@selector(doneLoadingTableViewData)];
    }
}
-(void)dealloc{
    if(mvTableView)[mvTableView release];
    if(searchDisplayController)[searchDisplayController release];
    if(searchResult.tableViewArray)[searchResult.tableViewArray release];
    if(hotMVResult.tableViewArray)[hotMVResult.tableViewArray release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


#pragma mark -
#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row>0){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        //[manager stopMusic];
        //[onlinePlayer stop];
        
        MVInformation *information=nil;
        if(displaySearch==NO){
            information=[hotMVResult.tableViewArray objectAtIndex:indexPath.row-1];
        }else{
            information=[searchResult.tableViewArray objectAtIndex:indexPath.row-1];
        }
        
        
        NSString *url = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
        
        MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL URLWithString:url]];  
        

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinishedCallback:)  name:MPMoviePlayerPlaybackDidFinishNotification  object:[playerViewController moviePlayer]];  
        
        [playerViewController.view setFrame:CGRectMake(0,-20,320, 480)];

        
        MPMoviePlayerController *player=[playerViewController moviePlayer];
        NSURL *tempUrl=[NSURL URLWithString:information.playURL];
        [player play];
        [player stop];
        [player setContentURL:tempUrl];
        [player play];
        
        [self presentModalViewController:playerViewController animated:YES];
        
        
    }
    
    
}

#pragma mark -
#pragma mark UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(displaySearch==NO){
        return [hotMVResult.tableViewArray count]+1;
    }else{
        return [searchResult.tableViewArray count]+1;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row==0){
        return 88.0f;
    }else {
        return 110.0f;
    }
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier=nil;
    static BOOL nibRegistered=NO;
    
    if(!nibRegistered){
        UINib *nib=[UINib nibWithNibName:@"MVCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"MVCellIdentifier"];
        nib=[UINib nibWithNibName:@"SearchBarCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:@"SearchBarCellIdentifier"];
        nibRegistered=YES;
    }
    
    if(indexPath.row==0){
        cellIdentifier=@"SearchBarCellIdentifier";
        SearchBarCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        searchDisplayController=[[UISearchDisplayController alloc]initWithSearchBar:cell.searchBar contentsController:self];
        
        [cell.segmentedControl addTarget:self action:@selector(segmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
        
        searchController = [[YCSearchController alloc] initWithDelegate:self
                                                searchDisplayController:searchDisplayController];
        
        return cell;
    }else {
        cellIdentifier=@"MVCellIdentifier";
        
        MVCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if(displaySearch==NO){
            MVInformation *information=[hotMVResult.tableViewArray objectAtIndex:indexPath.row-1];
            
            [cell setTitle:[information title]];
            [cell setInformation:[information information]];
            [cell setPicture:[information picture]];
        }else{
            MVInformation *information=[searchResult.tableViewArray objectAtIndex:indexPath.row-1];
            
            [cell setTitle:[information title]];
            [cell setInformation:[information information]];
            [cell setPicture:[information picture]];
        }
        return cell;
    }
}

#pragma mark -
#pragma mark MPMoviePlayerViewController CallBack

-(void)movieFinishedCallback:(MPMoviePlayerViewController*)controller{

}

#pragma mark -
#pragma mark UISegmentedControl CallBack

-(void)segmentedControlChanged:(UISegmentedControl*)segmentedControl{
    int index = segmentedControl.selectedSegmentIndex;
    if(index==1){
        if([searchResult.tableViewArray count]==0){
            [searchController setActive:YES animated:YES];
        }else{
            displaySearch=YES;
            [mvTableView setFooterRefreshViewHidden:YES];
            [mvTableView reloadData];
        }
    }else{
        [searchController setActive:NO animated:YES];
        displaySearch=NO;
        [mvTableView setFooterRefreshViewHidden:NO];
        [mvTableView reloadData];
    }
}


#pragma mark -
#pragma mark YCSearchControllerDelegate

-(NSArray*)searchController:(YCSearchController *)controller searchString:(NSString *)searchString{
    NSIndexPath *myIndexPath =[NSIndexPath indexPathForRow:0 inSection:0];
    
    SearchBarCell *cell =(SearchBarCell*)[mvTableView cellForRowAtIndexPath:myIndexPath];
    cell.segmentedControl.selectedSegmentIndex=1;
    
    lastSearchString=[NSString stringWithString:searchString];
    if(!searchResult.tableViewArray)searchResult.tableViewArray=[[NSMutableArray alloc]init];
    searchResult.nowPageAt=1;
    HotMVGetter *getter=[[[HotMVGetter alloc]init]autorelease];
    getter.delegate=self;
    [getter searchByString:searchString AndPage:1];
    displaySearch=YES;
    [cell.searchBar resignFirstResponder];
    [mvTableView setUserInteractionEnabled:NO];
    [SVProgressHUD showWithStatus:@"Getting Data..."];
    return nil;
}

-(void)searchEndedWithNothing{
    NSIndexPath *myIndexPath =[NSIndexPath indexPathForRow:0 inSection:0];
    
    SearchBarCell *cell =(SearchBarCell*)[mvTableView cellForRowAtIndexPath:myIndexPath];;
    cell.segmentedControl.selectedSegmentIndex=0;
    displaySearch=NO;
    [mvTableView setFooterRefreshViewHidden:NO];
    
    [mvTableView reloadData];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.y>-1){
        if(mvTableView.footerRefreshViewShowed)[mvTableView.footerRefreshView egoRefreshScrollViewDidScroll:scrollView];
    }
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (scrollView.contentOffset.y>-1) {
        if(mvTableView.footerRefreshViewShowed)[mvTableView.footerRefreshView egoRefreshScrollViewDidEndDragging:scrollView];
    }
	
}

#pragma mark -
#pragma mark Refresh Methods

- (void)doneLoadingTableViewData{
	gettingMore = NO;
    [mvTableView.footerRefreshView egoRefreshScrollViewDataSourceDidFinishedLoading:mvTableView];
	
}

-(void)getMoreData{
    if(!displaySearch){
        if(!hotMVResult.tableViewArray)hotMVResult.tableViewArray=[[NSMutableArray alloc]init];
        if(hotMVResult.nowPageAt<hotMVResult.pagesCount){
            hotMVResult.nowPageAt+=1;
            HotMVGetter *getter=[[[HotMVGetter alloc]init]autorelease];
            getter.delegate=self;
            [getter getHotMVWithPage:hotMVResult.nowPageAt];
        }else{
            [self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:2.0];
        }
    }else{
        if(!searchResult.tableViewArray)searchResult.tableViewArray=[[NSMutableArray alloc]init];
        if(searchResult.nowPageAt<searchResult.pagesCount){
            searchResult.nowPageAt+=1;
            HotMVGetter *getter=[[[HotMVGetter alloc]init]autorelease];
            getter.delegate=self;
            [getter searchByString:lastSearchString AndPage:searchResult.nowPageAt];
        }else{
            [self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:2.0];
        }
    }
}


#pragma mark -
#pragma mark EGORefreshTableHeaderViewDelegade

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
    
    if(view==mvTableView.footerRefreshView){
        [self getMoreData];
        gettingMore=YES;
    }
    
	
}

-(BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return gettingMore;
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	return [NSDate date];
	
}


@end
