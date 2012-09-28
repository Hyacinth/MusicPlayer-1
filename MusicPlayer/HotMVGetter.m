//
//  HotMVGetter.m
//  MusicPlayer
//
//  Created by Bill on 12-8-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "HotMVGetter.h"
#import "MVInformation.h"

@implementation HotMVGetter
@synthesize delegate;

-(void)getHotMVWithPage:(int)page{
    NSString *urlString=[NSString stringWithFormat:@"http://api.tudou.com/v3/gw?method=item.ranking&format=xml&appKey=1952e9844c5283d5&pageNo=%i&pageSize=20&channelId=14&sort=v",page];
    
    DFDownloader *downloader=[[DFDownloader alloc]init];
    downloader.delegate=self;
    [downloader startDownloadWithURLString:urlString Key:@"hotMVXML" Encoding:NSUTF8StringEncoding];
    [downloader release];
}

-(void)downloadFinishedWithResult:(NSString *)result Key:(NSString *)theKey{
    NSMutableArray *resultArray=[NSMutableArray array];
    int pages=0;
    NSArray *r=[result componentsSeparatedByString:@"<ItemInfo>"];
    for(int i=1;i<[r count];i++){
        MVInformation *information=[[MVInformation alloc]init];
        //视频信息
        NSString *itemInformation=[r objectAtIndex:i];
        itemInformation=[[itemInformation componentsSeparatedByString:@"</ItemInfo>"]objectAtIndex:0];
        //视频标题
        NSString *title=[[itemInformation componentsSeparatedByString:@"<title>"]objectAtIndex:1];
        title=[[title componentsSeparatedByString:@"</title>"]objectAtIndex:0];
        information.title=title;
        //视频描述
        NSString *description=nil;
        description=[[itemInformation componentsSeparatedByString:@"<description>"]objectAtIndex:1];
        description=[[description componentsSeparatedByString:@"</description>"]objectAtIndex:0];
        description=[description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(!description||[description isEqualToString:@""]){
            description=@"没有描述";
        }else{
            description=[NSString stringWithFormat:@"    %@",description];
        }
        information.information=description;
        //图片URL
        NSString *picURL=[[itemInformation componentsSeparatedByString:@"<picUrl>"]objectAtIndex:1];
        picURL=[[picURL componentsSeparatedByString:@"</picUrl>"]objectAtIndex:0];
        //UIImage图片
        NSURL *picDownloadURL=[[NSURL alloc]initWithString:picURL];
        NSData *imageData=[[NSData alloc] initWithContentsOfURL:picDownloadURL];
        UIImage *horBigPic=[UIImage imageWithData:imageData];
        [picDownloadURL release];
        [imageData release];
        information.picture=horBigPic;
        //播放URL
        //土豆视频的m3u8播放URL要从图片URL中提取
        NSArray *playURLArray=[picURL componentsSeparatedByString:@"/"];
        NSString *playURl=[NSString string];
        for(int i=3;i<[playURLArray count]-1;i++){
            playURl=[playURl stringByAppendingFormat:@"%@/",[playURLArray objectAtIndex:i]];
        }
        playURl=[NSString stringWithFormat:@"http://m3u8.tdimg.com/%@2.m3u8",playURl];
        information.playURL=playURl;
        //储存结果
        [resultArray addObject:[information autorelease]];
    }
    //总页数
    if([theKey isEqualToString:@"searchXML"]||[theKey isEqualToString:@"hotMVXML"]){
        NSString *count=[[result componentsSeparatedByString:@"<page>"]objectAtIndex:1];
        count=[[count componentsSeparatedByString:@"<totalCount>"]objectAtIndex:1];
        count=[[count componentsSeparatedByString:@"</totalCount>"]objectAtIndex:0];
        if([count intValue]>0){
            pages=[count intValue]/20;
        }
    }
    if(delegate){
        struct mvInformation information;
        information.pagesCount=pages;
        information.information=resultArray;
        [delegate downloadFinishedWithResult:information AndKey:theKey];
    }
    [self autorelease];
}

-(void)searchByString:(NSString *)theString AndPage:(int)page{
    NSString *urlString=[NSString stringWithFormat:@"http://api.tudou.com/v3/gw?method=item.search&appKey=1952e9844c5283d5&format=xml&kw=%@&pageNo=%i&pageSize=20&channelId=14&sort=v",theString,page];
    urlString=[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
    
    DFDownloader *downloader=[[DFDownloader alloc]init];
    downloader.delegate=self;
    NSLog(@"%i",page);
    NSString *theKey=(page==1)?@"searchXML":@"searchMoreXML";
    [downloader startDownloadWithURLString:urlString Key:theKey Encoding:NSUTF8StringEncoding];
    [downloader release];
}

@end
