# BRYHTMLParser

A fork of Ben Reeves’ [Objective-C HTML Parser](https://github.com/zootreeves/Objective-C-HMTL-Parser), containing some slight improvements and CocoaPods support.

## Installation

### CocoaPods

```bash
pod install BRYHTMLParser
```

### Manual

1. Open Your project in Xcode and drag and drop all `.h`/`.m` files into an appropriate folder
2. In the project settings add `/usr/include/libxml2` to the “Header search paths” field
3. Ctrl-Click the Frameworks group choose “Add -> Existing Frameworks” and from the list choose `libxml2.dylib`

## Usage

```objc
NSError *error = nil;
NSString *html =
    @"<ul>"
        "<li><input type='image' name='input1' value='string1value' /></li>"
        "<li><input type='image' name='input2' value='string2value' /></li>"
    "</ul>"
    "<span class='spantext'><b>Hello World 1</b></span>"
    "<span class='spantext'><b>Hello World 2</b></span>";
HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];

if (error) {
    NSLog(@"Error: %@", error);
    return;
}

HTMLNode *bodyNode = [parser body];

NSArray *inputNodes = [bodyNode findChildTags:@"input"];

for (HTMLNode *inputNode in inputNodes) {
    if ([[inputNode getAttributeNamed:@"name"] isEqualToString:@"input2"]) {
        NSLog(@"%@", [inputNode getAttributeNamed:@"value"]); //Answer to first question
    }
}

NSArray *spanNodes = [bodyNode findChildTags:@"span"];

for (HTMLNode *spanNode in spanNodes) {
    if ([[spanNode getAttributeNamed:@"class"] isEqualToString:@"spantext"]) {
        NSLog(@"%@", [spanNode rawContents]); //Answer to second question
    }
}

[parser release];
```
