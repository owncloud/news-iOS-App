//
//  HTMLNode.h
//  BRYHTMLParser
//
//  Created by Bryan Irace on 7/15/15.
//  Copyright (c) 2015 Bryan Irace. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(unsigned int, HTMLNodeType) {
    HTMLUnkownNode,
    
    HTMLHrefNode,
    HTMLTextNode,
    HTMLSpanNode,
    
    HTMLOlNode,
    HTMLUlNode,
    HTMLLiNode,
    
    HTMLImageNode,
    
    HTMLStrongNode,
    HTMLEmNode,
    HTMLDelNode,
    
    HTMLBoldNode,
    HTMLItalicNode,
    HTMLStrikeNode,
    
    HTMLPNode,
    HTMLBrNode,
    HTMLBlockQuoteNode,
    
    HTMLPreNode,
    HTMLCodeNode,
};

@protocol HTMLNode <NSObject>

/// Returns the first child element
@property (nonatomic, readonly) id <HTMLNode> firstChild;

/// Returns the plaintext contents of node
@property (nonatomic, readonly, copy) NSString *contents;

/// Returns the plaintext contents of this node + all children
@property (nonatomic, readonly, copy) NSString *allContents;

/// Returns the html contents of the node
@property (nonatomic, readonly, copy) NSString *rawContents;

/// Returns next sibling in tree
@property (nonatomic, readonly) id <HTMLNode> nextSibling;

/// Returns previous sibling in tree
@property (nonatomic, readonly) id <HTMLNode> previousSibling;

/// Returns the class name
@property (nonatomic, readonly, copy) NSString *className;

/// Returns the tag name
@property (nonatomic, readonly, copy) NSString *tagName;

/// Returns the parent
@property (nonatomic, readonly) id <HTMLNode> parent;

/// Returns the first level of children
@property (nonatomic, readonly, copy) NSArray *children;

/// Returns the node type if know
@property (nonatomic, readonly) HTMLNodeType nodetype;

/// Gets the attribute value matching tha name
- (NSString *)getAttributeNamed:(NSString *)name;

/// Find children with the specified tag name
- (NSArray *)findChildTags:(NSString *)tagName;

/// Looks for a tag name e.g. "h3"
- (id <HTMLNode>)findChildTag:(NSString *)tagName;

/// Returns a single child of class
- (id <HTMLNode>)findChildOfClass:(NSString *)className;

/// Returns all children of class
- (NSArray *)findChildrenOfClass:(NSString *)className;

/// Finds a single child with a matching attribute. Set `allowPartial` to match partial matches, e.g. <img src="http://www.google.com"> [findChildWithAttribute:@"src" matchingName:"google.com" allowPartial:TRUE]
- (id <HTMLNode>)findChildWithAttribute:(NSString *)attribute matchingName:(NSString *)className allowPartial:(BOOL)partial;

/// Finds all children with a matching attribute
- (NSArray *)findChildrenWithAttribute:(NSString *)attribute matchingName:(NSString *)className allowPartial:(BOOL)partial;

@end
