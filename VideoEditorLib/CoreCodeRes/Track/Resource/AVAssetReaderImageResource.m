//
//  AVAssetReaderImageResource.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/20/21.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import "AVAssetReaderImageResource.h"


@interface AVAssetReaderImageResource () {
    dispatch_queue_t _loadBufferQueue;
    NSOperationQueue *_operationQueue;
}

@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetReaderOutput *trackOutput;
@property (nonatomic, strong) NSMutableArray *sampleBuffers;
@property (nonatomic, assign) CMTime lastReaderTime;
@end


@implementation AVAssetReaderImageResource

- (instancetype)initWithAsset:(AVURLAsset *)asset {
    return [self initWithAsset:asset videoComposition:nil];
}

- (instancetype)initWithAsset:(AVURLAsset *)asset videoComposition:(AVVideoComposition * __nullable)videoComposition {
    if (self = [super init]) {
        self.asset = asset;
        self.videoComposition = videoComposition;
        CMTime duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration), 600);
        self.selectedTimeRange = CMTimeRangeMake(kCMTimeZero, duration);
        
        _loadBufferQueue = dispatch_queue_create("com.digiarty.mobilegroup.loadbuffer", NULL);
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        _operationQueue.name = @"com.digiarty.mobilegroup.loadQueue";
        
        _lastReaderTime = kCMTimeZero;
        
    }
    return self;
}

- (CIImage *)imageAtTime:(CMTime)time renderSize:(CGSize)renderSize {
    CMTime timeLineTime = [self sourceTimeForTimelineTime:time];
    CMSampleBufferRef sampleBuffer = [self loadSamplebufferForTime:timeLineTime];
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (sampleBuffer && imageBuffer) {
        return [CIImage imageWithCVPixelBuffer:imageBuffer];
    }

    return self.image;
}

#pragma mark - TODO: 解决 seek 问题
- (CMSampleBufferRef)loadSamplebufferForTime:(CMTime)time {
    CMSampleBufferRef currentSampleBuffer = NULL;
    if (CMTIME_COMPARE_INLINE(time, <, self.lastReaderTime) ||
        CMTimeGetSeconds(time) > CMTimeGetSeconds(self.lastReaderTime)+1.0) {
        [self cleanReader];
    }
    
    if (!self.assetReader || !self.trackOutput) {
        [self createAssetReaderOutputAtTime:time];
    }
    
    if (!self.assetReader || !self.trackOutput) {
        return nil;
    }
    
    self.lastReaderTime = time;
    
    CMSampleBufferRef sampleBuffer = self.trackOutput.copyNextSampleBuffer;
    while (sampleBuffer) {
        if (CMSampleBufferGetImageBuffer(sampleBuffer)) {
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            if (CMTimeGetSeconds(pts) > CMTimeGetSeconds(time)-0.017) {
                currentSampleBuffer = sampleBuffer;
                break;
            }
        }
        
        sampleBuffer = self.trackOutput.copyNextSampleBuffer;
    }
    return currentSampleBuffer;
}

- (void)cleanReader {
    if (self.assetReader) {
        [self.assetReader cancelReading];
    }
    self.assetReader = nil;
    self.trackOutput = nil;
}

- (void)createAssetReaderOutputAtTime:(CMTime)time {
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:self.asset error:nil];
    NSArray *tracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    if (!self.asset || !reader || tracks.count <= 0) {
        return;
    }
    
    AVAssetReaderOutput *trackOutput = NULL;
    AVVideoComposition *videoComposition = self.videoComposition;
    NSDictionary *outputSettings = @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferOpenGLESCompatibilityKey : @(YES),
        (id)kCVPixelBufferMetalCompatibilityKey : @(YES)
    };
    if (videoComposition) {
        AVAssetReaderVideoCompositionOutput *output = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:tracks videoSettings:outputSettings];
        output.videoComposition = self.videoComposition;
        trackOutput = output;
    }else {
        AVAssetTrack *track = tracks.firstObject;
        trackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:outputSettings];
    }
    
    trackOutput.alwaysCopiesSampleData = NO;
    
    if (![reader canAddOutput:trackOutput]) {
        return;
    }
    
    [reader addOutput:trackOutput];
    reader.timeRange = CMTimeRangeFromTimeToTime(time, CMTimeRangeGetEnd(self.selectedTimeRange));
    [reader startReading];
    
    self.assetReader = reader;
    self.trackOutput = trackOutput;
}

#pragma mark - NSCoping
- (id)copyWithZone:(NSZone *)zone {
    AVAssetReaderImageResource *resource = [[super class] allocWithZone:zone];
    resource.asset = self.asset;
    return resource;
}


@end
