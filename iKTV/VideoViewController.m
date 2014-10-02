//
//  VideoViewController.m
//  iKTV
//
//  Created by Steve Yeom on 9/30/14.
//  Copyright (c) 2014 2nd Jobs. All rights reserved.
//


#import "VideoViewController.h"

#import "Reachability.h"


@interface VideoViewController ()
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation VideoViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSString *url = [self loadLastViewedChannel];
  [self playVideoWithURL:url];
  [self.moviePlayer play];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playVideo:) name:@"noti" object:nil];
    
    /*
     Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [self updateInterfaceWithReachability:self.internetReachability];
    
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    [self.wifiReachability startNotifier];
    [self updateInterfaceWithReachability:self.wifiReachability];
}

- (void)playVideoWithURL:(NSString *)url{
  NSURL *movieURL = [NSURL URLWithString:url];
  self.moviePlayer.contentURL = movieURL;
  [self.moviePlayer play];
  [self saveCurrnentChannel:url];
}

- (void)playVideo:(NSNotification *)notification {
  if ([[notification name] isEqualToString:@"noti"]){
    NSString *url = [notification object];
    [self playVideoWithURL:url];
  }
}

- (NSString *)loadLastViewedChannel {
  NSString *channel = [[NSUserDefaults standardUserDefaults] stringForKey:@"channel"];
  if (channel == nil) {
    channel = @"http://120.50.142.154/hls/ag0stream.m3u8";
  }
  return channel;
}

- (void)saveCurrnentChannel:(NSString *)channel {
  [[NSUserDefaults standardUserDefaults] setObject:channel forKey:@"channel"];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}


/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}


- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    if (reachability == self.internetReachability)
    {
    }
    
    if (reachability == self.wifiReachability)
    {
    }
    
    
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    BOOL connectionRequired = [reachability connectionRequired];
    NSString* statusString = @"";
    
    switch (netStatus)
    {
        case NotReachable:        {
            statusString = NSLocalizedString(@"Access Not Available", @"Text field text for access is not available");
            /*
             Minor interface detail- connectionRequired may return YES even when the host is unreachable. We cover that up here...
             */
            connectionRequired = NO;
            break;
        }
            
        case ReachableViaWWAN:        {
            statusString = NSLocalizedString(@"Reachable WWAN", @"");
            
            BOOL cannotShowAlert = [[[NSUserDefaults standardUserDefaults] objectForKey:@"kDoNotShowAlertAnyMore"] boolValue];
            if (!cannotShowAlert) {
                UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"안내"
                                                                  message:@"WiFi 연결이 되지 않았습니다. 3G 또는 LTE로 접속시 데이터 요금이 발생할 수 있습니다."
                                                                 delegate:self
                                                        cancelButtonTitle:@"TV 걍 안볼래요!"
                                                        otherButtonTitles:@"괜챦아요. 그냥 TV 볼래요!", @"이 메세지 다시 보지 않기", nil];
                [anAlert show];
            }
            
            break;
        }
        case ReachableViaWiFi:        {
            statusString= NSLocalizedString(@"Reachable WiFi", @"");
            break;
        }
    }
    
    if (connectionRequired)
    {
        NSString *connectionRequiredFormatString = NSLocalizedString(@"%@, Connection Required", @"Concatenation of status string with connection requirement");
        statusString= [NSString stringWithFormat:connectionRequiredFormatString, statusString];
    }

}

#pragma mark - UIAlert delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            // "괜챦아요. 그냥 TV 볼래요!"
            // do nothing, just dismiss
            break;
        case 2:
            // "이 메세지 다시 보지 않기"
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"kDoNotShowAlertAnyMore"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            break;
        case 0:
            // cancel? TV 안볼래요.
            [self.moviePlayer stop];
            exit(0); //지옥의 묵시록
            break;
        default:
            break;
    }
}

@end
