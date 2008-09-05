
(plugin-filter "Add Red Border" under "Nu"
     (set nsimage (image NSImage))
     (nsimage lockFocus)
     ((NSColor redColor) set)
     (set path (NSBezierPath bezierPathWithRect:(list 0.5 0.5 (- ((nsimage size) 0) 1) (- ((nsimage size) 1) 1))))
     (path setLineWidth:10)
     (path stroke)
     (nsimage unlockFocus)
     (CIImage imageWithData:(nsimage TIFFRepresentation)))