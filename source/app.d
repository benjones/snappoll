import vibe.vibe;

import std.conv : to;
import core.time : seconds;
import std.algorithm;
import std.array;

import core.sys.posix.netinet.in_;


void main()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1", "0.0.0.0", "::"];
    settings.accessLogToConsole = true;


    auto router = new URLRouter;
    router.get("/", (req, res){
            logInfo("calling serveIndex");
            logInfo(req.clientAddress.toAddressString());

            if(isLocalhost(req.clientAddress)){
                res.render!("admin.dt");
            } else {
                res.render!("index.dt");
            }
        });

    router.get("/qrCode", (res, resp){
        sendJoinQRCode(res, resp, settings.port);
    });


    router.get("/eventStream", &eventStream);

    router.get("*", serveStaticFiles("./public"));

    foreach(k, v; router.getAllRoutes){
        logInfo("route: " ~ k.to!string ~ " -> " ~ v.to!string);
    }

	auto listener = listenHTTP(settings, router);
	scope (exit)
	{
		listener.stopListening();
	}

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
	runApplication();
}

void eventStream(HTTPServerRequest req, HTTPServerResponse res){
    res.headers["Content-Type"] = "text/event-stream;";

    auto writer = res.bodyWriter;
    int count = 0;
    while(true){
        const message = "data: message number: " ~ count.to!string ~ "\n\n";
        writer.write(message);
        writer.flush();
        sleep(1.seconds);
        count++;
    }
}


bool isLocalhost(const ref NetworkAddress address) @safe {
    import std.socket : AddressFamily, InternetAddress, Internet6Address;
    //import core.sys.posix.netinet.in_ : IN6_IS_ADDR_LOOPBACK; //TODO use when druntime gets updated
    import std.algorithm.comparison: equal;

    const family = address.family;
    switch(family){
        case AddressFamily.UNIX: return true;
        case AddressFamily.INET:
            const addr4 = address.sockAddrInet4.sin_addr.s_addr;
            return addr4 == InternetAddress.parse("127.0.0.1");
        case AddressFamily.INET6:
            const addr6 = address.sockAddrInet6.sin6_addr.s6_addr;
            return addr6[].equal(Internet6Address.parse("::1")[]);//when druntime is fixed: IN6_IS_ADDR_LOOPBACK(&addr6);
        default:
            return false;
    }
}

bool isPublicIP(const scope sockaddr* addr) @trusted {

    if(addr.sa_family == AF_INET){
        const addr4 = cast(sockaddr_in*)(addr);
        return addr4.sin_addr.s_addr != 0x100007F;
    } else if(addr.sa_family == AF_INET6){
        //todo: make const once druntime is fixed
        auto addr6 = cast(sockaddr_in6*)(addr);
        return !(IN6_IS_ADDR_LOOPBACK(&addr6.sin6_addr) || IN6_IS_ADDR_LINKLOCAL(&addr6.sin6_addr));
    } else {
        return false;
    }
}


struct LinkedListAdaptor(alias nextField, T){
 	T current;
    @safe:
   	nothrow:

    this(T head){
     	current = head;
    }

    bool empty() const {
    	return current == null;
    }

    T front() {
     	return current;
    }

    void popFront() {
		current = __traits(child, current, nextField);
    }
}

void sendJoinQRCode(HTTPServerRequest req, HTTPServerResponse res, int port) @trusted{
    version(OSX){
        import core.sys.darwin.ifaddrs;
    }
    version(linux){
        import core.sys.linux.ifaddrs;
    }

    import core.sys.posix.sys.socket;
    import core.stdc.string: strlen;


    ifaddrs *addrs;
    getifaddrs(&addrs);
    scope(exit) freeifaddrs(addrs);

    auto rng = LinkedListAdaptor!(ifaddrs.ifa_next, ifaddrs*)(addrs);

    auto publicAddrs = rng.filter!(x => x.ifa_addr.isPublicIP).array;

    /*    foreach(addr; publicAddrs){
            logInfo(addr.ifa_name[0..addr.ifa_name.strlen]);
            if(addr.ifa_addr.sa_family == AF_INET){
                const addr4 = cast(sockaddr_in*)(addr.ifa_addr);
                logInfo(to!string(addr4.sin_addr.s_addr, 16));
            } else {
                const addr6 = cast(sockaddr_in6*)(addr.ifa_addr);
                logInfo(to!string((addr6.sin6_addr.s6_addr16[]).map!(x => x.to!string(16)).join(":")));
            }

            }*/

    logInfo("public addresses");
    publicAddrs.each!( (addr) @trusted {
            logInfo(addr.ifa_name[0..addr.ifa_name.strlen]);
            if(addr.ifa_addr.sa_family == AF_INET){
                const addr4 = cast(sockaddr_in*)(addr.ifa_addr);
                logInfo(to!string(addr4.sin_addr.s_addr, 16));
            } else {
                const addr6 = cast(sockaddr_in6*)(addr.ifa_addr);
                logInfo(to!string((addr6.sin6_addr.s6_addr16[]).map!(x => x.to!string(16)).join(":")));
            }
            });



    const addr = publicAddrs.front();
    const family = addr.ifa_addr.sa_family;

    logInfo(family == AF_INET ? "IPV4" : "IPV6");

    char[max(INET_ADDRSTRLEN, INET6_ADDRSTRLEN)] buffer;
    auto ptr = inet_ntop(family,
                         family == AF_INET ?
                         cast(void*)&((cast(sockaddr_in*)(addr.ifa_addr)).sin_addr) :
                         cast(void*)&((cast(sockaddr_in6*)(addr.ifa_addr)).sin6_addr),
                         buffer.ptr,
                         buffer.length);
    if(ptr is null){
        logInfo("un oh");
        throw new Exception("inet_ntop failed");
    }

    logInfo(to!string(cast(ulong)(buffer.ptr), 16) ~ " " ~ to!string(cast(ulong)ptr, 16));

    import std.format;
    const address = format!"http://%s:%s/"(ptr.fromStringz(), port);
    logInfo("address: " ~ address);


    import qrcode;
    scope svg = new Svg();
    svg.setWidth(500);
    svg.setHeight(500);
    svg.setRoundDimensions(true);
	svg.setBackgroundColor(new Rgb(0,0,0));
	svg.setForegroundColor(new Rgb(200,200,200));

    scope writer = new QrCodeWriter(svg);
    const svgString = writer.writeString(address);

    res.contentType = "image/svg+xml";
    res.writeBody(svgString);

}
