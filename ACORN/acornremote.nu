(load "nu")      	;; essentials

(load "NuBonjour")

(global AF_INET 2)
(global NSFileHandleNotificationDataItem "NSFileHandleNotificationDataItem")
(global NSUTF8StringEncoding 4)

(class ClientHandler is NSObject
     (ivars)
     
     (- initWithSocket:socket is
        (super init)
        (set @socket socket)
        (set @data (NSMutableData data))
        self)
     
     (- close is (@socket close))
     
     (- (void)socketConnected:(id)sock is
        (puts "handler connected"))
     
     (- (void)socketConnectFailed:(id)sock is
        (puts "handler connect failed")
        (puts "error is #{(sock error)}"))
     
     (- (void)socketBecameReadable:(id)sock is
        (set data (sock readData))
        (set string ((NSString alloc) initWithData:data encoding:NSUTF8StringEncoding))
        (puts (+ ">> " string))
        (if (/quit/ findInString:string)
            (sock close))
        (if (eq (data length) 0)
            (sock close)))
     
     (- (void) do:(id) string is
        (@data appendData:(string dataUsingEncoding:NSUTF8StringEncoding))
        (if (@socket isWritable)
            (self socketBecameWritable:@socket)))
     
     (- (void)socketBecameWritable:(id)sock is
        (unless (eq (@data length) 0)
                (try
                    (set @data (NSMutableData dataWithData:(sock writeData:@data)))
                    (catch (exception)
                           (puts (exception description))
                           (sock close))))))

(class RemoteNuBrowser is NSObject
     (ivars)
     (ivar-accessors)
     
     (- init is
        (super init)
        (set @browser ((NSNetServiceBrowser alloc) init))
        (set @services (array))
        (@browser setDelegate:self)
        ;; Passing in "" for the domain causes us to browse in the default browse domain,
        ;; which currently will always be "local".  The service type should be registered
        ;; with IANA, and it should be listed at <http://www.iana.org/assignments/port-numbers>.
        ;; At minimum, the service type should be registered at <http://www.dns-sd.org/ServiceTypes.html>
        ;; Our service type "wwdcpic" isn't listed because this is just sample code.
        (@browser searchForServicesOfType:"_nuserve._tcp." inDomain:"")
        self)
     
     ;; This object is the delegate of its NSNetServiceBrowser object. We're only interested in services-related methods,
     ;; so that's what we'll call.
     (- (void)netServiceBrowser:(id)aNetServiceBrowser didFindService:(id)aNetService moreComing:(BOOL)moreComing is
        (@services addObject:aNetService)
        (puts "found service #{(aNetService name)}")
        (self connect:0))
     
     (- (void)netServiceBrowser:(id)aNetServiceBrowser didRemoveService:(id)aNetService moreComing:(BOOL)moreComing is
        ;; This case is slightly more complicated. We need to find the object in the list and remove it.
        ;(@services removeObjectIdenticalTo:aNetService)
        (set enumerator (@services objectEnumerator))
        (while (set currentNetService (enumerator nextObject))
               (if (currentNetService isEqual:aNetService)
                   (@services removeObject:currentNetService)
                   (break)))
        (puts "removed service #{(aNetService name)}")
        (if (and @serviceBeingResolved (@serviceBeingResolved isEqual:aNetService))
            (if $handler
                ($handler close)
                (set $handler nil))
            (@serviceBeingResolved stop)
            (set @serviceBeingResolved nil)))
     
     (- (void)netServiceDidResolveAddress:(id)sender is
        (if (> ((sender addresses) count) 0)
            ;; Iterate through addresses until we find an IPv4 address
            (set mySocketAddress nil)
            ((sender addresses) each:
             (do (address)
                 (if (eq (NuSocketAddress familyForAddress:address) AF_INET)
                     (set mySocketAddress (AGInetSocketAddress addressWithInetSocketData:address)))))
            (if mySocketAddress
                ;; Cancel the resolve now that we have an IPv4 address.
                (sender stop)
                (set @serviceBeingResolved nil)
                (puts (mySocketAddress hostAddress))
                (puts ((mySocketAddress port) stringValue))
                (set remoteConnection (AGSocket tcpSocket))
                (remoteConnection setDelegate:(set $iphone ((ClientHandler alloc) initWithSocket:remoteConnection)))
                (remoteConnection connectToAddressInBackground:mySocketAddress))))
     
     (- (void)connect:(int)index is
        ;;  Make sure to cancel any previous resolves.
        (if @serviceBeingResolved
            (@serviceBeingResolved stop)
            (set @serviceBeingResolved nil))
        (set @serviceBeingResolved (@services objectAtIndex:index))
        (@serviceBeingResolved setDelegate:self)
        (@serviceBeingResolved resolve)))

(set $remote ((RemoteNuBrowser alloc) init))

(global -- (macro -- (($iphone do: (margs stringValue)))))
