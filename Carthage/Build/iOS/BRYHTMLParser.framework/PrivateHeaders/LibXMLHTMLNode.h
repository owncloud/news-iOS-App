//
//  HTMLNode.h
//  StackOverflow
//
//  Created by Ben Reeves on 09/03/2010.
//  Copyright 2010 Ben Reeves. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTMLNode.h"

@interface LibXMLHTMLNode : NSObject <HTMLNode>

struct _xmlNode;

/// Init with a lib xml node (shouldn't need to be called manually). Use [parser doc] to get the root Node
- (instancetype)initWithXMLNode:(struct _xmlNode *)xmlNode NS_DESIGNATED_INITIALIZER;

@end
