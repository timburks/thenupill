(load "WebKit")

(if NO ;; this was my original attempt to do this. The code below is (I think) much cleaner
    (class WebView
         (- snapshot is
            (set bounds ((((self mainFrame) frameView) documentView) bounds))
            (self setFrame:bounds)
            (set data (self dataWithPDFInsideRect:bounds))
            (set image ((NSImage alloc) initWithData:data))
            (set bitmapImageRep ((NSBitmapImageRep alloc) initWithData:(image TIFFRepresentation)))
            ((NSDocumentController sharedDocumentController) newDocumentWithImageData:(nsimage TIFFRepresentation))
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
          (NSURL URLWithString:"http://www.neontology.com/maps.php?s=15&lat=37.38319&long=-122.1173&w=800&h=600"))))

(class WebPageImageScraper is NSObject
     (ivars) (ivar-accessors)
     
     (- init is
        ;; When the view has loaded, we will expand it to fit its content.
        (set @view ((WebView alloc) initWithFrame:'(0 0 1 1)))
        (@view setFrameLoadDelegate:self)
        self)
     
     (- (void) loadPath:(id)path is
        (@view setFrame:'(0 0 1 1))
        (set @loading YES)
        ((@view mainFrame) loadRequest:
         (NSURLRequest requestWithURL:(NSURL URLWithString:path))))
     
     (- (void) webView:(id) sender didFinishLoadForFrame:(id) frame is
        (set @loading NO)
        (set bounds ((sender mainFrame) description))
        (if (eq frame (sender mainFrame))
            (then (self snapshot))))
     
     (- (id) snapshot is
        (set bounds ((((@view mainFrame) frameView) documentView) bounds))
        (@view setFrame:bounds)
        (set data (@view dataWithPDFInsideRect:bounds))
        (set image ((NSImage alloc) initWithData:data))
        (set bitmapImageRep ((NSBitmapImageRep alloc) initWithData:(image TIFFRepresentation)))
        ;;((bitmapImageRep representationUsingType:NSPNGFileType properties:nil) writeToFile:"/Users/tim/Desktop/snapshot.png" atomically:NO)
        ((NSDocumentController sharedDocumentController) newDocumentWithImageData:(image TIFFRepresentation))))

(class MapScraper is WebPageImageScraper
     
     (- loadMapWithLatitude:(id)lat longitude:(id)long is
        (self loadMapWithScale:14 latitude:lat longitude:long width:320 height:320))
     
     (- loadMapWithScale:(id)s latitude:(id)lat longitude:(id)long width:(id)width height:(id)height is
        (set path "http://www.neontology.com/maps.php?s=#{s}&lat=#{lat}&long=#{long}&w=#{width}&h=#{height}")
        (self loadPath:path)))

(global scrape
        (do (path)
            (puts path)
            (unless $scraper (set $scraper ((WebPageImageScraper alloc) init)))
            ($scraper loadPath:path)))

(global scrape-map
        (do (lat long)
            (unless $mapscraper (set $mapscraper ((MapScraper alloc) init)))
            ($mapscraper loadMapWithLatitude:lat longitude:long)))
