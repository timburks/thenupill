(load "WebKit")

(class WebView
     (- snapshot is
        (set bounds ((((self mainFrame) frameView) documentView) bounds))
        (self setFrame:bounds)
        (set data (self dataWithPDFInsideRect:bounds))
        (set image ((NSImage alloc) initWithData:data))
        (set bitmapImageRep ((NSBitmapImageRep alloc) initWithData:(image TIFFRepresentation)))
        ((bitmapImageRep representationUsingType:NSPNGFileType properties:nil) writeToFile:"/Users/tim/Desktop/snapshot.png" atomically:NO)))

(class WebViewDelegate is NSObject
     (- (void) webView:(id) sender didFinishLoadForFrame:(id) frame is
        (set bounds ((sender mainFrame) description))
        (if (eq frame (sender mainFrame))
            (then (sender snapshot)))))

(set view ((WebView alloc) initWithFrame:'(0 0 100 100)))
(set delegate ((WebViewDelegate alloc) init))
(view setFrameLoadDelegate:delegate)
((view mainFrame) loadRequest:
 (NSURLRequest requestWithURL:
      (NSURL URLWithString:"http://www.neontology.com/maps.php?s=15&lat=37.38319&long=-122.1173&w=800&h=600")))
