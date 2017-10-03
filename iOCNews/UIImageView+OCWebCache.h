/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <WebImage/SDWebImageCompat.h>
#import <WebImage/SDWebImageManager.h>

@interface UIImageView (OCWebCache)

- (void)setRoundedImageWithURL:(NSURL *)url;

- (void)cancelCurrentRoundedImageLoad;


@end
