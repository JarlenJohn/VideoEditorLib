//
//  Timeline.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/8/21.
//

#import <Foundation/Foundation.h>
#import "CompositionProvider.h"
#import "CompositionProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface Timeline : NSObject

@property(nonatomic, assign) CGSize renderSize;
@property(nonatomic, strong) CIColor *backgroundColor;

//MARK: - 主要内容，支持转场

/*
 videoChannel和audioChannel支持转场，当时需要自己负责更新provider的时间范围
 转场仅在两个provider的时间范围有重合的时候有效
 在更新videoChannel之后需要调用 reloadVideoStartTime，在更新完audioChannel之后需要调用
 reloadAudioStartTime，这两个方法将会基于provider的时间范围和转场时长更新provider的timeRange
 */
@property(nonatomic, strong) NSArray <id<TransitionableVideoProvider>>*videoChannel;
@property(nonatomic, strong) NSArray <id<TransitionableAudioProvider>>*audioChannel;

//其他内容，可放置在时间线的任何位置
@property(nonatomic, strong) NSArray <id<VideoProvider>>*overlays;
@property(nonatomic, strong) NSArray <id<AudioProvider>>*audios;

//全局效果
@property(nonatomic, strong) id<VideoCompositionProvider> passingThroughVideoCompositionProvider;

@end

@interface Timeline(SortTime)

+ (void)reloadVideoStartTimeWithProviders:(NSArray <id<TransitionableVideoProvider>>*)providers;
+ (void)reloadAudioStartTimeWithProviders:(NSArray <id<TransitionableAudioProvider>>*)providers;

@end

NS_ASSUME_NONNULL_END
