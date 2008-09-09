
(acorn-filter "Add Red Border" under "Nu"
     (set nsimage (image NSImage))
     (nsimage lockFocus)
     ((NSColor redColor) set)
     (set path (NSBezierPath bezierPathWithRect:(list 0.5 0.5 (- ((nsimage size) 0) 1) (- ((nsimage size) 1) 1))))
     (path setLineWidth:10)
     (path stroke)
     
     ('((20 blueColor)
        (50 yellowColor)
        (80 greenColor)
        (110 redColor)) each:
       (do (pair)
           ("Take the Nu Pill"
                  drawAtPoint:(list 40 (pair car))
                  withAttributes:(dict NSForegroundColorAttributeName ((eval (cons 'NSColor (pair cdr))) colorWithAlphaComponent:0.7)
                                       NSFontAttributeName (NSFont boldSystemFontOfSize:30.0)))))
     
     (nsimage unlockFocus)
     (CIImage imageWithData:(nsimage TIFFRepresentation)))
