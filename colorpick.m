//
//  main.m
//  color-pick
//
//  Created by Johan Nordberg on 2011-09-20.
//  Copyright 2011 FFFF00 Agents AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface NSColor (NSColorHexadecimalValue)
@end

@implementation NSColor (NSColorHexadecimalValue)

// NSColorHexadecimalValue from http://developer.apple.com/library/mac/#qa/qa1576/_index.html
-(NSString *)hexValue {
  CGFloat redFloatValue, greenFloatValue, blueFloatValue;
  CGFloat alphaFloatValue;
  int redIntValue, greenIntValue, blueIntValue;
  int alphaIntValue;
  NSString *redHexValue, *greenHexValue, *blueHexValue;
  NSString *alphaHexValue;

  // Convert the NSColor to the RGB color space before we can access its components
  NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

  if(convertedColor) {
    // Get the red, green, and blue components of the color
    [convertedColor getRed:&redFloatValue green:&greenFloatValue blue:&blueFloatValue alpha:&alphaFloatValue];

    // Convert the components to numbers (unsigned decimal integer) between 0 and 255
    redIntValue=redFloatValue*255.99999f;
    greenIntValue=greenFloatValue*255.99999f;
    blueIntValue=blueFloatValue*255.99999f;
    alphaIntValue=alphaFloatValue*255.99999f;

    // Convert the numbers to hex strings
    redHexValue=[NSString stringWithFormat:@"%02x", redIntValue];
    greenHexValue=[NSString stringWithFormat:@"%02x", greenIntValue];
    blueHexValue=[NSString stringWithFormat:@"%02x", blueIntValue];
    alphaHexValue=[NSString stringWithFormat:@"%02x", alphaIntValue];

    // Concatenate the red, green, and blue components' hex strings together
    return [NSString stringWithFormat:@"%@%@%@%@", alphaHexValue, redHexValue, greenHexValue, blueHexValue];
  }
  return nil;
}

// color from hex found from http://www.karelia.com/cocoa_legacy/Foundation_Categories/NSColor__Instantiat.m
+ (NSColor *)colorFromHex:(NSString *)inColorString {
  NSColor *result = nil;
  unsigned int colorCode = 0;
  unsigned char redByte, greenByte, blueByte;
  unsigned char alphaByte;

  if ([inColorString length] == 3) {
    NSString *newColor = [[NSString alloc] initWithFormat:@"%@%@%@%@%@%@",
      [inColorString substringWithRange: NSMakeRange(0,1)],
      [inColorString substringWithRange: NSMakeRange(0,1)],
      [inColorString substringWithRange: NSMakeRange(1,1)],
      [inColorString substringWithRange: NSMakeRange(1,1)],
      [inColorString substringWithRange: NSMakeRange(2,1)],
      [inColorString substringWithRange: NSMakeRange(2,1)]];
    inColorString = [newColor autorelease];
  } else if ([inColorString length] == 4) {//#ARGB
    NSString *newColor = [[NSString alloc] initWithFormat:@"%@%@%@%@%@%@%@%@",
      [inColorString substringWithRange: NSMakeRange(0,1)],
      [inColorString substringWithRange: NSMakeRange(0,1)],
      [inColorString substringWithRange: NSMakeRange(1,1)],
      [inColorString substringWithRange: NSMakeRange(1,1)],
      [inColorString substringWithRange: NSMakeRange(2,1)],
      [inColorString substringWithRange: NSMakeRange(2,1)],
      [inColorString substringWithRange: NSMakeRange(3,1)],
      [inColorString substringWithRange: NSMakeRange(3,1)]];
    inColorString = [newColor autorelease];
  }

  if (nil != inColorString) {
    NSScanner *scanner = [NSScanner scannerWithString:inColorString];
    (void) [scanner scanHexInt:&colorCode]; // ignore error
  }
  alphaByte = 0xFF;
  if (colorCode > 0x00FFffFF) {
    alphaByte   = (unsigned char) (colorCode >> 24);
  }
  redByte   = (unsigned char) (colorCode >> 16);
  greenByte = (unsigned char) (colorCode >> 8);
  blueByte  = (unsigned char) (colorCode);  // masks off high bits
  result = [NSColor colorWithCalibratedRed:(float)redByte / 0xff
                                     green:(float)greenByte/ 0xff
                                      blue:(float)blueByte / 0xff
                                     alpha:(float)alphaByte / 0xff];
  return result;
}

@end

@interface Picker : NSObject <NSApplicationDelegate, NSWindowDelegate> {
  NSColorPanel *panel; // weak ref
}

- (void)show;
- (void)writeColor;
- (void)exit;

@end

@implementation Picker

- (void)show {
  // setup panel and its accessory view

  NSView *accessoryView = [[NSView alloc] initWithFrame:(NSRect){{0, 0}, {220, 30}}];

  NSButton *button = [[NSButton alloc] initWithFrame:(NSRect){{110, 4}, {110 - 8, 24}}];
  [button setButtonType:NSMomentaryPushInButton];
  [button setBezelStyle:NSRoundedBezelStyle];
  button.title = @"Pick";
  button.action = @selector(writeColor);
  button.target = self;

  NSButton *cancelButton = [[NSButton alloc] initWithFrame:(NSRect){{8, 4}, {110 - 8, 24}}];
  [cancelButton setButtonType:NSMomentaryPushInButton];
  [cancelButton setBezelStyle:NSRoundedBezelStyle];
  cancelButton.title = @"Cancel";
  cancelButton.action = @selector(exit);
  cancelButton.target = self;

  [accessoryView addSubview:[button autorelease]];
  [accessoryView addSubview:[cancelButton autorelease]];

  panel = [NSColorPanel sharedColorPanel];
  [panel setDelegate:self];
  [panel setShowsAlpha:YES]; // TODO: support for rgba() output values
  [panel setAccessoryView:[accessoryView autorelease]];
  [panel setDefaultButtonCell:[button cell]];

  // load user settings
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *color = [defaults stringForKey:@"startColor"];
  if (color != nil) {
    [panel setColor:[NSColor colorFromHex:color]];
  }
  [panel setMode:[defaults integerForKey:@"mode"]]; // will be 0 if not set, wich is NSGrayModeColorPanel

  // show panel
  [panel makeKeyAndOrderFront:self];
  //[NSApp runModalForWindow:panel]; // resets panel position
}

- (void)writeColor {
  NSString *hex = [panel.color hexValue];

  // save color and current mode to defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:hex forKey:@"startColor"];
  [defaults setInteger:panel.mode forKey:@"mode"];
  [defaults synchronize]; // force a save since we are exiting

  // write color to stdout
  NSFileHandle *stdOut = [NSFileHandle fileHandleWithStandardOutput];
  [stdOut writeData:[hex dataUsingEncoding:NSASCIIStringEncoding]];

  [self exit];
}

- (void)exit {
  [panel close];
}

// panel delegate methods

- (void)windowWillClose:(NSNotification *)notification {
  [NSApp terminate:self];
}

// application delegate methods

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
  ProcessSerialNumber psn = {0, kCurrentProcess};
  TransformProcessType(&psn, kProcessTransformToForegroundApplication);
  SetFrontProcess(&psn);
  [self show];
}

@end

int main (int argc, const char * argv[]) {
  NSString *startColor = @"FFFC860D"; //sublime icon orange
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if (argc >= 2){
    startColor = [NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding];
    [defaults setObject:startColor forKey:@"startColor"];
  } else {
    NSString *storedColor = [defaults stringForKey:@"startColor"];
    if (storedColor != nil) {
      startColor = storedColor;
    }
  }

  int mode = [defaults integerForKey:@"mode"];
  if (mode == -1) {
    mode = (NSColorPanelMode)NSWheelModeColorPanel;
  }
  [defaults setObject:[NSNumber numberWithInt: mode] forKey:@"mode"];
  [defaults synchronize]; // force a save

  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  NSApplication *app = [NSApplication sharedApplication];
  app.delegate = [[[Picker alloc] init] autorelease];
  [app run];
  [pool drain];
  return 0;
}
