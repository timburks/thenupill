;; upload this code to your iphone

(set UIImagePNGRepresentation (NuBridgedFunction functionWithName:"UIImagePNGRepresentation" signature:"@@"))

(class NSMutableData
     (- (void) appendString:(id) string is
        (puts (+ "appending string: " string))
        (self appendData:(string dataUsingEncoding:NSUTF8StringEncoding))))

(class RequestAgent is NSObject
     (ivars)
     
     (- (void) setCredential:(id) credential is (set @credential credential))
     
     (- (void)run:(id) actions is
        (set @actions (cdr actions))
        ((car actions) self))
     
     (- (void)makeRequest:(id) request is
        (puts "making request")
        (set @theRequest request)
        (set @theConnection ((NSURLConnection alloc) initWithRequest:@theRequest delegate:self))
        (set @receivedData (NSMutableData data)))
     
     (- (void)connection:(id)connection didReceiveResponse:(id)response is (@receivedData setLength:0))
     
     (- (void)connection:(id)connection didReceiveData:(id)data is (@receivedData appendData:data))
     
     (- (void)connection:(id)connection didReceiveAuthenticationChallenge:(id) challenge is
        (puts "challenged!")
        ((challenge sender) useCredential:@credential forAuthenticationChallenge:challenge))
     
     (- (void)connection:(id)connection didFailWithError:(id)error is
        (puts (+ "Connection failed, error " (error localizedDescription) ((error userInfo) description))))
     
     (- (void)connectionDidFinishLoading:(id)connection is
        (puts "finished loading")
        (set @result ((NSString alloc) initWithData:@receivedData encoding:NSUTF8StringEncoding))
        (if @actions
            (set block (car @actions))
            (set @actions (cdr @actions))
            (block self))))

(global UIImagePickerControllerSourceTypePhotoLibrary 0)
(global UIImagePickerControllerSourceTypeCamera 1)
(global UIImagePickerControllerSourceTypeSavedPhotosAlbum 2)

(set $source UIImagePickerControllerSourceTypeCamera)

(class PictureTakerViewController is UIViewController
     (ivars)
     
     (- (void) loadView is
        (set viewFrame ((UIScreen mainScreen) applicationFrame))
        (set @view ((UIView alloc) initWithFrame:viewFrame))
        (self setView:@view))
     
     (- (void) startCamera is
        ;(set @locator ((Locator alloc) init))
        ;(@locator locate)
        (set @locator nil)
        (set @picker ((UIImagePickerController alloc) init))
        (@picker setSourceType:$source)
        (@picker setDelegate:self)
        (@picker setAllowsImageEditing:YES)
        (if NO
            (((@picker view) subviews) each:
             (do (v)
                 (puts "subview")
                 ((v instanceMethods) each:
                  (do (m) (puts (m name)))))))
        (self presentModalViewController:@picker animated:YES)
        YES)
     
     (- (void)imagePickerController:(id)picker
        didFinishPickingImage:(id)image
        editingInfo:(id)editingInfo is
        (set $image (UIImagePNGRepresentation image))
        (if $image
            (then
                 (puts "uploading image")
                 ;; upload the image
                 (set myLocation
                      (if @locator
                          then (+ ((@locator latitude) stringValue) " " ((@locator longitude) stringValue))
                          else ""))
                 
                 (unless @agent (set @agent ((RequestAgent alloc) init)))
                 (@agent run:
                         (list
                              (do (self)
                                  # post an image to a url
                                  (set url (NSURL URLWithString:@"http://#{$host}:3000/postimage"))
                                  (set request (NSMutableURLRequest requestWithURL:url))
                                  (request setHTTPMethod:"POST")
                                  (set boundary "1n2b5blks9854kl234")
                                  (set contentType (+ "multipart/form-data; boundary=" boundary))
                                  (request addValue:contentType forHTTPHeaderField:"Content-Type")
                                  (set body (NSMutableData data))
                                  (puts "building form")
                                  (body appendData:((+ "--" boundary "\r\n") dataUsingEncoding:NSUTF8StringEncoding))
                                  (body appendData:("Content-Disposition: form-data; name=\"name\"\r\n\r\n"
                                                    dataUsingEncoding:NSUTF8StringEncoding))
                                  (body appendData:("image.jpg" dataUsingEncoding:NSUTF8StringEncoding))
                                  (body appendData:((+ "\r\n--" boundary "\r\n") dataUsingEncoding:NSUTF8StringEncoding))
                                  (body appendData:("Content-Disposition: form-data; name=\"image\"\r\n"
                                                    dataUsingEncoding:NSUTF8StringEncoding))
                                  (body appendData:("Content-Type: image/jpg4\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding))
                                  (body appendData:$image)
                                  ;;(body appendData:((+ "\r\n--" boundary "\r\n") dataUsingEncoding:NSUTF8StringEncoding))
                                  ;;(body appendData:("Content-Disposition: form-data; name=\"location\"\r\n" dataUsingEncoding:NSUTF8StringEncoding))
                                  ;;(body appendData:(myLocation dataUsingEncoding:NSUTF8StringEncoding))
                                  (body appendData:((+ "\r\n--" boundary "--\r\n") dataUsingEncoding:NSUTF8StringEncoding))
                                  (puts "setting body")
                                  (request setHTTPBody:body)
                                  (self makeRequest:request))
                              (do (self)
                                  (puts (@result description))))))
            (else (puts "error creating image")))
        ((picker parentViewController) dismissModalViewControllerAnimated:YES)
        ((((UIApplication sharedApplication) delegate) navigationController)
         popViewControllerAnimated:YES))
     
     (- (void)imagePickerControllerDidCancel:(id)picker is
        (show "cancelled")
        (picker dismissModalViewControllerAnimated:YES)
        ((((UIApplication sharedApplication) delegate) navigationController)
         popViewControllerAnimated:YES)))

(class ApplicationDelegate
     
     (- (void)snap:(id)sender is
        (unless @pictureTakerViewController
                (set @pictureTakerViewController ((PictureTakerViewController alloc) init)))
        (@navigationController pushViewController:@pictureTakerViewController animated:YES)
        (@pictureTakerViewController startCamera)))

(puts "activating")

;; change the button title and add a photo-taking action
(set button
     ((((UIApplication sharedApplication) delegate) helloViewController) button))
(button setTitle:"Snap" forStates:UIControlStateNormal)
(button addTarget:((UIApplication sharedApplication) delegate) action:"snap:" forControlEvents:UIControlEventTouchUpInside)

;; just for fun, make the image background transparent
(((((UIApplication sharedApplication) delegate) helloViewController) imageView) setAlpha:0.5)

(puts "code uploaded successfully")
