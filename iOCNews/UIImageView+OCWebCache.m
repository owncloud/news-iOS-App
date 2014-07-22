/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+OCWebCache.h"
#import "objc/runtime.h"

static char operationArticleImageKey;

@implementation UIImageView (OCWebCache)

- (void)setRoundedImageWithURL:(NSURL *)url {
    [self cancelCurrentRoundedImageLoad];

    self.image = [UIImage imageNamed:@"placeholder"];
    
    if (url)
    {
        __weak UIImageView *wself = self;
        id<SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadImageWithURL:url options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe(^
                                    {
                                        __strong UIImageView *sself = wself;
                                        if (!sself) return;
                                        if (image) {
                                            CGFloat width = image.size.width;
                                            CGFloat height = image.size.height;
                                            CGFloat targetWidth = sself.bounds.size.width;
                                            CGFloat targetHeight = sself.bounds.size.height;
                                            CGFloat scaleFactor = 0.0;
                                            CGFloat scaledWidth = targetWidth;
                                            CGFloat scaledHeight = targetHeight;
                                            CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
                                            
                                            if (!CGSizeEqualToSize(image.size, sself.bounds.size)) {
                                                CGFloat widthFactor = targetWidth / width;
                                                CGFloat heightFactor = targetHeight / height;
                                                
                                                if (widthFactor > heightFactor) {
                                                    scaleFactor = widthFactor; // scale to fit height
                                                } else {
                                                    scaleFactor = heightFactor; // scale to fit width
                                                }
                                                
                                                scaledWidth  = width * scaleFactor;
                                                scaledHeight = height * scaleFactor;
                                                
                                                // center the image
                                                if (widthFactor > heightFactor) {
                                                    thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
                                                } else {
                                                    if (widthFactor < heightFactor) {
                                                        thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
                                                    }
                                                }
                                            }
                                            
                                            UIGraphicsBeginImageContextWithOptions(sself.bounds.size, NO, 0.0);
                                            
                                            CGRect thumbnailRect = CGRectZero;
                                            thumbnailRect.origin = thumbnailPoint;
                                            thumbnailRect.size.width  = scaledWidth;
                                            thumbnailRect.size.height = scaledHeight;
                                            
                                            int radius;
                                            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                                                radius = 18;
                                            } else {
                                                radius = 9;
                                            }
                                            
                                            [[UIBezierPath bezierPathWithRoundedRect:sself.bounds cornerRadius:radius] addClip];
                                            
                                            [image drawInRect:thumbnailRect];
                                            
                                            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                                            
                                            UIGraphicsEndImageContext();
                                            sself.image = newImage;
                                            [sself setNeedsLayout];
                                            
                                        }
                                    });
        }];
        objc_setAssociatedObject(self, &operationArticleImageKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)cancelCurrentRoundedImageLoad
{
    // Cancel in progress downloader from queue
    id<SDWebImageOperation> operation = objc_getAssociatedObject(self, &operationArticleImageKey);
    if (operation)
    {
        [operation cancel];
        objc_setAssociatedObject(self, &operationArticleImageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
