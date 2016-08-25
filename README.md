
## Installation

GPCustomSegment is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "GPCustomSegment"
```
## Example and Usage
![ScreenShot](https://raw.githubusercontent.com/gprokopchuk/Screenshots/master/gpcustomsegment.png)

  
```objective-c
    _switchSegment = [[GPCustomSegment alloc] initWithImages:@[@"image", @"image",@"image"]
                                          disabledImageColor:[UIColor lightGrayColor]
                                          selectedImageColor:[UIColor yellowColor]
                                           pressureViewColor:[UIColor redColor]
                                             backgroundColor:[UIColor whiteColor]
                                                 borderColor:[UIColor clearColor]
                                                    andFrame:CGRectMake(30, 50, 150, 50)];
    [_switchSegment addTarget:self
                           action:@selector(segmentedControlValueChanged:)
                 forControlEvents:UIControlEventValueChanged];
                 
    [self.view addSubview:_switchSegment];
```

## Author

George Prokopchuk, prokopchukgeorge@icloud.com

## License

GPCustomSegment is available under the MIT license. See the LICENSE file for more info.


