//
//  ImageCompositionGroupProvider.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/16/21.
//

#import <Foundation/Foundation.h>
#import "CompositionProvider.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ImageCompositionProvider <CompositionTimeRangeProvider, VideoCompositionProvider>


@end

@interface ImageCompositionGroupProvider : NSObject <VideoCompositionProvider>

@property(nonatomic, weak) id<VideoCompositionProvider> passingThroughVideoCompositionProvider;

@property (nonatomic, strong) NSArray <id<ImageCompositionProvider>>*imageCompositionProviders;

@end

NS_ASSUME_NONNULL_END
