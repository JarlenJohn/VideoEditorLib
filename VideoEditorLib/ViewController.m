//
//  ViewController.m
//  VideoEditorLib
//
//  Created by zhuzhanlong on 8/24/21.
//

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "ViewController.h"
#import "AVAssetTrackResource.h"
#import "TrackItem.h"
#import "Timeline.h"
#import "CompositionGenerator.h"
#import "ImageCompositionGroupProvider.h"
#import "ImageResource.h"
#import "ImageOverlayItem.h"
#import "KeyframeVideoConfiguration.h"
#import "TimeRangeHelper.h"
#import "AVAssetReverseImageResource.h"
#import "AVAssetReaderImageResource.h"
#import "AudioTransition.h"
#import "APLCompositionDebugView.h"

@interface ViewController ()

@property (nonatomic, strong) AVPlayer *testPlayer;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) APLCompositionDebugView *debugView;

@property (nonatomic, strong) NSArray *datasource;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    _datasource = @[@"simplePlayerItem", @"overlayPlayerItem", @"transitionPlayerItem", @"keyframePlayerItem", @"fourSquareVideoPlayerItem", @"testReaderOutput", @"reversePlayerItem", @"twoVideoPlayerItem"];
    [self.tableView reloadData];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
//    //Apple提供的音视频合成调试视图
//    AVPlayerItem *playerItem = [self fourSquareVideoPlayerItem];
//    self.testPlayer = [AVPlayer playerWithPlayerItem:playerItem];
//    _debugView = [[APLCompositionDebugView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.height*0.5-100)];
//    [self.view addSubview:_debugView];
//    [_debugView synchronizeToPlayItem:self.testPlayer.currentItem];
}

#pragma mark - NSTableViewDataSource, NSTableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = @"ReuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    NSString *title = [_datasource objectAtIndex:indexPath.row];
    cell.textLabel.text = title;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *title = cell.textLabel.text;
    
    SEL aselector = NSSelectorFromString(title);
    AVPlayerItem *playerItem = [self performSelector:aselector];
    if (playerItem) {
        AVPlayerViewController *playerVc = [[AVPlayerViewController alloc] init];
        playerVc.player = [AVPlayer playerWithPlayerItem:playerItem];
        [self.navigationController pushViewController:playerVc animated:YES];
    }
}

#pragma mark - 朱测试方法开始
-(AVPlayerItem *)simplePlayerItem {
    NSURL *bambooUrl = [[NSBundle mainBundle] URLForResource:@"bamboo" withExtension:@"mp4"];
    AVURLAsset *bambooAsset = [AVURLAsset assetWithURL:bambooUrl];
    AVAssetTrackResource *trackResource = [[AVAssetTrackResource alloc] initWithAsset:bambooAsset];
    TrackItem *trackItem = [[TrackItem alloc] initWithResource:trackResource];
    trackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;

    Timeline *timeline = [[Timeline alloc] init];
    timeline.videoChannel = @[trackItem];
    timeline.audioChannel = @[trackItem];
    timeline.renderSize = CGSizeMake(1920, 1080);
    
    CompositionGenerator *generator = [[CompositionGenerator alloc] initWithTimeline:timeline];
    AVPlayerItem *playerItem = [generator buildPlayerItem];
    return playerItem;
}

-(AVPlayerItem *)overlayPlayerItem {
    NSURL *bambooUrl = [[NSBundle mainBundle] URLForResource:@"bamboo" withExtension:@"mp4"];
    AVURLAsset *bambooAsset = [AVURLAsset assetWithURL:bambooUrl];
    AVAssetTrackResource *trackResource = [[AVAssetTrackResource alloc] initWithAsset:bambooAsset];
    TrackItem *trackItem = [[TrackItem alloc] initWithResource:trackResource];
    trackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;

    Timeline *timeline = [[Timeline alloc] init];
    timeline.videoChannel = @[trackItem];
    timeline.audioChannel = @[trackItem];
    timeline.renderSize = CGSizeMake(1920, 1080);
    
    //passingThroughVideoCompositionProvider
    ImageCompositionGroupProvider *imageCompositionGroupProvider = [[ImageCompositionGroupProvider alloc] init];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"overlay" withExtension:@"jpg"];
    CIImage *image = [[CIImage alloc] initWithContentsOfURL:url];
    ImageResource *resource = [[ImageResource alloc] initWithImage:image duration:CMTimeMakeWithSeconds(3, NSEC_PER_SEC)];
    ImageOverlayItem *imageCompositionProvider = [[ImageOverlayItem alloc] initWithResource:resource];
    imageCompositionProvider.startTime = CMTimeMakeWithSeconds(1, 600);
    CGRect frame = CGRectMake(100, 500, 400, 400);
    imageCompositionProvider.videoConfiguration.contentMode = BaseContentModeAspectCustom;
    imageCompositionProvider.videoConfiguration.frame = frame;
    imageCompositionProvider.videoConfiguration.transform = CGAffineTransformMakeRotation(M_PI_4);
    
    KeyframeVideoConfiguration *keyframeConfiguration = [[KeyframeVideoConfiguration alloc] init];
    NSArray *timeValues = [NSArray arrayWithObjects:@[@0.0, @0],@[@0.5, @1.0], @[@2.5, @1.0], @[@3.0, @0.0], nil];
    for (NSArray *timeValue in timeValues) {
        double time = [timeValue.firstObject doubleValue];
        float value = [timeValue.lastObject floatValue];
        OpacityKeyframeValue *opacityKeyframeValue = [[OpacityKeyframeValue alloc] init];
        opacityKeyframeValue.opacity = value;
        
        Keyframe *keyFrame = [[Keyframe alloc] initWithTime:CMTimeMakeWithSeconds(time, 600) value:opacityKeyframeValue];
        [keyframeConfiguration insert:keyFrame];
    }
    [imageCompositionProvider.videoConfiguration.configurations addObject:keyframeConfiguration];
    
    KeyframeVideoConfiguration *transformKeyframeConfiguration = [[KeyframeVideoConfiguration alloc] init];
    NSArray *transTimeValues = @[
        @[@0.0, @[@1.0, @0, [NSValue valueWithCGPoint:CGPointZero]]],
        @[@1.0, @[@1.0, @M_PI, [NSValue valueWithCGPoint:CGPointMake(100, 80)]]],
        @[@2.0, @[@1.0, @(2*M_PI), [NSValue valueWithCGPoint:CGPointMake(300, 240)]]],
        @[@3.0, @[@1.0, @0, [NSValue valueWithCGPoint:CGPointZero]]],
    ];
    for (NSArray *timeValue in transTimeValues) {
        double time = [timeValue.firstObject doubleValue];
        NSArray *value = [timeValue lastObject];
        TransformKeyframeValue *transformKeyframeValue = [[TransformKeyframeValue alloc] init];
        transformKeyframeValue.scale = [[value firstObject] floatValue];
        transformKeyframeValue.rotation = [[value objectAtIndex:1] floatValue];
        transformKeyframeValue.translation = [[value lastObject] CGPointValue];
        Keyframe *keyFrame = [[Keyframe alloc] initWithTime:CMTimeMakeWithSeconds(time, 600) value:transformKeyframeValue];
        [transformKeyframeConfiguration insert:keyFrame];
    }
    [imageCompositionProvider.videoConfiguration.configurations addObject:transformKeyframeConfiguration];
    imageCompositionGroupProvider.imageCompositionProviders = @[imageCompositionProvider];
    
    timeline.passingThroughVideoCompositionProvider = imageCompositionGroupProvider;
    CompositionGenerator *generator = [[CompositionGenerator alloc] initWithTimeline:timeline];
    AVPlayerItem *playerItem = [generator buildPlayerItem];
    return playerItem;
}

- (AVPlayerItem *)keyframePlayerItem {
    NSURL *bambooUrl = [[NSBundle mainBundle] URLForResource:@"bamboo" withExtension:@"mp4"];
    AVURLAsset *bambooAsset = [AVURLAsset assetWithURL:bambooUrl];
    AVAssetTrackResource *trackResource = [[AVAssetTrackResource alloc] initWithAsset:bambooAsset];
    TrackItem *trackItem = [[TrackItem alloc] initWithResource:trackResource];
    trackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;

    KeyframeVideoConfiguration *transformKeyframeConfiguration = [[KeyframeVideoConfiguration alloc] init];
    NSArray *transTimeValues = @[
        @[@0.0, @[@1.0, @0, [NSValue valueWithCGPoint:CGPointZero]]],
        @[@1.0, @[@1.2, @(M_PI/20), [NSValue valueWithCGPoint:CGPointMake(100, 80)]]],
        @[@2.0, @[@1.5, @(M_PI/15), [NSValue valueWithCGPoint:CGPointMake(300, 240)]]],
        @[@3.0, @[@1.0, @0, [NSValue valueWithCGPoint:CGPointZero]]],
    ];
    for (NSArray *timeValue in transTimeValues) {
        double time = [timeValue.firstObject doubleValue];
        NSArray *value = [timeValue lastObject];
        TransformKeyframeValue *transformKeyframeValue = [[TransformKeyframeValue alloc] init];
        transformKeyframeValue.scale = [[value firstObject] floatValue];
        transformKeyframeValue.rotation = [[value objectAtIndex:1] floatValue];
        transformKeyframeValue.translation = [[value lastObject] CGPointValue];
        Keyframe *keyFrame = [[Keyframe alloc] initWithTime:CMTimeMakeWithSeconds(time, 600) value:transformKeyframeValue];
        [transformKeyframeConfiguration insert:keyFrame];
    }
    [trackItem.videoConfiguration.configurations addObject:transformKeyframeConfiguration];
    
    Timeline *timeline = [[Timeline alloc] init];
    timeline.videoChannel = @[trackItem];
    timeline.audioChannel = @[trackItem];
    timeline.renderSize = CGSizeMake(1920, 1080);
    
    CompositionGenerator *generator = [[CompositionGenerator alloc] initWithTimeline:timeline];
    AVPlayerItem *playerItem = [generator buildPlayerItem];
    return playerItem;
}

- (AVPlayerItem *)twoVideoPlayerItem {
    CGSize renderSize = CGSizeMake(1920, 1080);
    
    NSURL *bambooUrl = [[NSBundle mainBundle] URLForResource:@"bamboo" withExtension:@"mp4"];
    AVURLAsset *bambooAsset = [AVURLAsset assetWithURL:bambooUrl];
    AVAssetTrackResource *trackResource = [[AVAssetTrackResource alloc] initWithAsset:bambooAsset];
    trackResource.selectedTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(1800, 600));
    TrackItem *bambooTrackItem = [[TrackItem alloc] initWithResource:trackResource];
    bambooTrackItem.videoConfiguration.contentMode = BaseContentModeAspectCustom;
    CGFloat width = renderSize.width / 2;
    CGFloat height = width * (9.0/16);
    bambooTrackItem.videoConfiguration.frame = CGRectMake(0, (renderSize.height - height)/2, width, height);
    
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cute" withExtension:@"mp4"];
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
    AVAssetTrackResource *secResource = [[AVAssetTrackResource alloc] initWithAsset:urlAsset];
    secResource.selectedTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(2500, 600));
    TrackItem *seaTrackItem = [[TrackItem alloc] initWithResource:secResource];
    seaTrackItem.audioConfiguration.volume = 0.5;
    seaTrackItem.videoConfiguration.contentMode = BaseContentModeAspectCustom;
    CGFloat secHeight = renderSize.height;
    CGFloat secWidth = height * (9.0/16);
    CGRect seaTrackRect = CGRectMake(renderSize.width / 2 + (renderSize.width / 2 - secWidth) / 2, (renderSize.height - secHeight) / 2, secWidth, secHeight);
    seaTrackItem.videoConfiguration.frame = seaTrackRect;
    
    Timeline *timeline = [[Timeline alloc] init];
    timeline.videoChannel = @[bambooTrackItem];
    timeline.audioChannel = @[bambooTrackItem];
    
    timeline.overlays = @[seaTrackItem];
    timeline.audios = @[seaTrackItem];
    timeline.renderSize = renderSize;
    
    CompositionGenerator *generator = [[CompositionGenerator alloc] initWithTimeline:timeline];
    AVPlayerItem *playerItem = [generator buildPlayerItem];
    return playerItem;
}

- (AVPlayerItem *)fourSquareVideoPlayerItem {
    NSURL *bambooUrl = [[NSBundle mainBundle] URLForResource:@"bamboo" withExtension:@"mp4"];
    AVURLAsset *bambooAsset = [AVURLAsset assetWithURL:bambooUrl];
    AVAssetTrackResource *trackResource = [[AVAssetTrackResource alloc] initWithAsset:bambooAsset];
    TrackItem *bambooTrackItem = [[TrackItem alloc] initWithResource:trackResource];
    bambooTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
    NSURL *testUrl = [[NSBundle mainBundle] URLForResource:@"sea" withExtension:@"mp4"];
    AVURLAsset *testurlAsset = [AVURLAsset assetWithURL:testUrl];
    AVAssetTrackResource *testResource = [[AVAssetTrackResource alloc] initWithAsset:testurlAsset];
    TrackItem *seaTrackItem = [[TrackItem alloc] initWithResource:testResource];
    seaTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cute" withExtension:@"mp4"];
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
    AVAssetTrackResource *secResource = [[AVAssetTrackResource alloc] initWithAsset:urlAsset];
    TrackItem *flyTrackItem = [[TrackItem alloc] initWithResource:secResource];
    flyTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
    AVAssetTrackResource *track2Resource = [[AVAssetTrackResource alloc] initWithAsset:bambooAsset];
    TrackItem *bambooTrack2Item = [[TrackItem alloc] initWithResource:track2Resource];
    bambooTrack2Item.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
    NSArray *trackItems = @[flyTrackItem, bambooTrackItem, seaTrackItem, bambooTrack2Item];
    Timeline *timeline = [[Timeline alloc] init];
    timeline.videoChannel = trackItems;
    timeline.audioChannel = trackItems;
    
    @try {
        [Timeline reloadVideoStartTimeWithProviders:timeline.videoChannel];
        [Timeline reloadAudioStartTimeWithProviders:timeline.audioChannel];
    } @catch (NSException *exception) {
        NSLog(@"exception = %@", exception.description);
    }
    
    CGSize renderSize = CGSizeMake(1920, 1080);
    timeline.renderSize = renderSize;
    
    {//timeline.overlays
        CGSize foursquareRenderSize = CGSizeMake(renderSize.width/2, renderSize.height/2);
        NSMutableArray <id<VideoProvider>>*overlays = [[NSMutableArray alloc] init];
        
        CMTime duration = kCMTimeZero;
        for (TrackItem *item in trackItems) {
            duration = CMTimeAdd(item.duration, duration);
        }
        CMTimeRange fullTimeRange = CMTimeRangeMake(kCMTimeZero, duration);
        
        // Update main item's frame
        CGRect(^frameWithIndex)(NSUInteger index) = ^(NSUInteger index) {
            CGRect resultRect = CGRectZero;
            switch (index) {
                case 0:
                    resultRect = CGRectMake(0, 0, foursquareRenderSize.width, foursquareRenderSize.height);
                    break;
                case 1:
                    resultRect = CGRectMake(foursquareRenderSize.width, 0, foursquareRenderSize.width, foursquareRenderSize.height);
                    break;
                case 2:
                    resultRect = CGRectMake(0, foursquareRenderSize.height, foursquareRenderSize.width, foursquareRenderSize.height);
                    break;
                case 3:
                    resultRect = CGRectMake(foursquareRenderSize.width, foursquareRenderSize.height, foursquareRenderSize.width, foursquareRenderSize.height);
                    break;
                default:
                    break;
            }
            return resultRect;
        };
        
        [trackItems enumerateObjectsUsingBlock:^(TrackItem *mainTrackItem, NSUInteger offset, BOOL * _Nonnull stop) {
            CGRect frame = frameWithIndex(offset % 4);
            
            mainTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
            mainTrackItem.videoConfiguration.frame = frame;
            
            NSArray *timeRanges = [TimeRangeHelper substructTimeRange:mainTrackItem.timeRange from:fullTimeRange];
            for(NSValue *timeRangeValue in timeRanges) {
                CMTimeRange timeRange = [timeRangeValue CMTimeRangeValue];
                
                if (!CMTIMERANGE_IS_EMPTY(timeRange)) {
                    TrackItem *staticTrackItem = [mainTrackItem copy];
                    staticTrackItem.startTime = timeRange.start;
                    staticTrackItem.duration = timeRange.duration;
                    
                    if (CMTIME_COMPARE_INLINE(timeRange.start, <=, mainTrackItem.timeRange.start)) {
                        CMTime start = staticTrackItem.resource.selectedTimeRange.start;
                        staticTrackItem.resource.selectedTimeRange = CMTimeRangeMake(start, CMTimeMake(1, 30));
                    }else {
                        CMTime start = CMTimeSubtract(CMTimeRangeGetEnd(staticTrackItem.resource.selectedTimeRange), CMTimeMake(1, 30));
                        staticTrackItem.resource.selectedTimeRange = CMTimeRangeMake(start, CMTimeMake(1, 30));
                    }
                    
                    [overlays addObject:staticTrackItem];
                }
            }
        }];
        
        timeline.overlays = overlays;
    }
    
    CompositionGenerator *generator = [[CompositionGenerator alloc] initWithTimeline:timeline];
    AVPlayerItem *playerItem = [generator buildPlayerItem];
    return playerItem;
}

-(AVPlayerItem *)reversePlayerItem {
    NSURL *testUrl = [[NSBundle mainBundle] URLForResource:@"sea" withExtension:@"mp4"];
    AVURLAsset *testurlAsset = [AVURLAsset assetWithURL:testUrl];
    AVAssetReverseImageResource *testResource = [[AVAssetReverseImageResource alloc] initWithAsset:testurlAsset];
    TrackItem *seaTrackItem = [[TrackItem alloc] initWithResource:testResource];
    seaTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
    Timeline *timeline = [[Timeline alloc] init];
    timeline.videoChannel = @[seaTrackItem];
    timeline.renderSize = CGSizeMake(1920, 1080);
    
    CompositionGenerator *generator = [[CompositionGenerator alloc] initWithTimeline:timeline];
    AVPlayerItem *playerItem = [generator buildPlayerItem];
    return playerItem;
}

- (AVPlayerItem *)testReaderOutput {
    NSURL *bambooUrl = [[NSBundle mainBundle] URLForResource:@"bamboo" withExtension:@"mp4"];
    AVURLAsset *bambooAsset = [AVURLAsset assetWithURL:bambooUrl];
    AVAssetTrackResource *trackResource = [[AVAssetTrackResource alloc] initWithAsset:bambooAsset];
    TrackItem *bambooTrackItem = [[TrackItem alloc] initWithResource:trackResource];
    bambooTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"cute" withExtension:@"mp4"];
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
    AVAssetTrackResource *secResource = [[AVAssetTrackResource alloc] initWithAsset:urlAsset];
    [secResource setSpeed:2];
    TrackItem *flyTrackItem = [[TrackItem alloc] initWithResource:secResource];
    flyTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
    Timeline *timeline = [[Timeline alloc] init];
    timeline.videoChannel = @[bambooTrackItem, flyTrackItem];
    timeline.renderSize = CGSizeMake(1920, 1080);
    
    @try {
        [Timeline reloadVideoStartTimeWithProviders:timeline.videoChannel];
    } @catch (NSException *exception) {
        NSLog(@"exception = %@", exception.description);
    }
    
    {//passingThroughVideoCompositionProvider
        ImageCompositionGroupProvider *imageCompositionGroupProvider = [[ImageCompositionGroupProvider alloc] init];
        NSURL *seaUrl = [[NSBundle mainBundle] URLForResource:@"sea" withExtension:@"mp4"];
        AVURLAsset *seaUrlAsset = [AVURLAsset assetWithURL:seaUrl];
        AVAssetReaderImageResource *resource = [[AVAssetReaderImageResource alloc] initWithAsset:seaUrlAsset];
        resource.selectedTimeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, CMTimeMakeWithSeconds(4, 600));
        
        ImageOverlayItem *imageCompositionProvider = [[ImageOverlayItem alloc] initWithResource:resource];
        imageCompositionProvider.startTime = CMTimeMakeWithSeconds(3, 600);
        CGRect frame = CGRectMake((timeline.renderSize.width-600)*0.5, (timeline.renderSize.height-500)*0.5, 600, 400);
        imageCompositionProvider.videoConfiguration.contentMode = BaseContentModeAspectCustom;
        imageCompositionProvider.videoConfiguration.frame = frame;

        imageCompositionGroupProvider.imageCompositionProviders = @[imageCompositionProvider];
        
        timeline.passingThroughVideoCompositionProvider = imageCompositionGroupProvider;
    }
    
    CompositionGenerator *generator = [[CompositionGenerator alloc] initWithTimeline:timeline];
    AVPlayerItem *playerItem = [generator buildPlayerItem];
    return playerItem;
}

- (AVPlayerItem *)transitionPlayerItem {
    NSURL *bambooUrl = [[NSBundle mainBundle] URLForResource:@"bamboo" withExtension:@"mp4"];
    AVURLAsset *bambooAsset = [AVURLAsset assetWithURL:bambooUrl];
    AVAssetTrackResource *trackResource = [[AVAssetTrackResource alloc] initWithAsset:bambooAsset];
    TrackItem *bambooTrackItem = [[TrackItem alloc] initWithResource:trackResource];
    bambooTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"overlay" withExtension:@"jpg"];
//    CIImage *image = [[CIImage alloc] initWithContentsOfURL:url];
//    ImageResource *resource = [[ImageResource alloc] initWithImage:image duration:CMTimeMakeWithSeconds(3, 600)];
//    TrackItem *overlayTrackItem = [[TrackItem alloc] initWithResource:resource];
//    overlayTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
    NSURL *testUrl = [[NSBundle mainBundle] URLForResource:@"sea" withExtension:@"mp4"];
    AVURLAsset *testurlAsset = [AVURLAsset assetWithURL:testUrl];
    AVAssetTrackResource *testResource = [[AVAssetTrackResource alloc] initWithAsset:testurlAsset];
    TrackItem *seaTrackItem = [[TrackItem alloc] initWithResource:testResource];
    seaTrackItem.videoConfiguration.contentMode = BaseContentModeAspectFit;
    
    CMTime transitionDuration = CMTimeMakeWithSeconds(2, 600);
    bambooTrackItem.videoTransition = [[FadeTransition alloc] initWithDuration:transitionDuration];
    bambooTrackItem.audioTransition = [[FadeInOutAudioTransition alloc] initWithDuration:transitionDuration];
    
//    overlayTrackItem.videoTransition = [[BoundingUpTransition alloc] initWithDuration:transitionDuration];
    
    Timeline *timeline = [[Timeline alloc] init];
    timeline.videoChannel = @[bambooTrackItem, seaTrackItem];
    timeline.audioChannel = @[bambooTrackItem, seaTrackItem];
    timeline.renderSize = CGSizeMake(1920, 1080);
    
    @try {
        [Timeline reloadVideoStartTimeWithProviders:timeline.videoChannel];
    } @catch (NSException *exception) {
        NSLog(@"exception = %@", exception.description);
    }
    
    CompositionGenerator *generator = [[CompositionGenerator alloc] initWithTimeline:timeline];
    AVPlayerItem *playerItem = [generator buildPlayerItem];
    return playerItem;
}
#pragma mark - 朱测试结束


@end
