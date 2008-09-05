;; @file server.nu
;; @discussion An embedded web server for Acorn.
;;
;; @copyright Copyright (c) 2008 Tim Burks, Neon Design Technology, Inc.

;; Load this file into a running app to add a web server.
;; It requires NuHTTP. Specifically /Library/Frameworks/NuHTTP.framework.

(load "NuHTTP:server")
(set server ((NuHTTPController alloc) initWithPort:3000))
(set handlers (array))

(get "/" <<-END
<html>
<head></head>
<body>
<h1>Hello from Acorn</h1>
<img src="/image" />
</body>
</html>
END)

(get "/image"
     (set image ((NSApplication sharedApplication) applicationIconImage))
     (set bitmapImageRep ((NSBitmapImageRep alloc) initWithData:(image TIFFRepresentation)))
     ((response objectForKey:"headers") setObject:"image/png" forKey:"Content-Type")
     (bitmapImageRep representationUsingType:NSPNGFileType properties:nil))

;; image uploads
(post "/postimage"
      (puts (request description))
      (puts ((request "headers") description))
      (set contentType ((request "headers") "Content-Type"))
      (puts "content-type")
      (puts contentType)
      (set boundary ((contentType componentsSeparatedByString:"=") lastObject))
      (puts "boundary")
      (puts boundary)
      (set postBody (request "body"))
      (set postDictionary (postBody multipartDictionaryWithBoundary:boundary))
      (set image (postDictionary objectForKey:"image"))
      (set data (image objectForKey:"data"))
      (set nsimage ((NSImage alloc) initWithData:data))
      ((NSDocumentController sharedDocumentController) newDocumentWithImageData:(nsimage TIFFRepresentation))
      (data writeToFile:"/image.png" atomically:NO)
      "thanks for uploading!")

(server setHandlers:handlers)

