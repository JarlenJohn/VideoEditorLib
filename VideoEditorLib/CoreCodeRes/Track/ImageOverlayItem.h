//
//  ImageOverlayItem.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/16/21.
//

#import <Foundation/Foundation.h>
#import "ImageCompositionGroupProvider.h"
#import "VideoConfiguration.h"


NS_ASSUME_NONNULL_BEGIN

@class ImageResource;

@interface ImageOverlayItem : NSObject <ImageCompositionProvider, NSCopying>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) ImageResource *resource;
@property (nonatomic, strong) VideoConfiguration *videoConfiguration;


- (instancetype)initWithResource:(ImageResource *)resource;

@end

NS_ASSUME_NONNULL_END
