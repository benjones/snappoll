import vibe.vibe;

import std.conv : to;
import core.time : seconds;
import std.algorithm;
import std.array;
import std.traits : ReturnType;

import core.sys.posix.netinet.in_;


@safe struct Question {
    string question;
    string[] answers;

    void toHTML(HTTPServerResponse res){
        res.render!("question.dt", question, answers);
    }
}

@safe struct PollResults {

    int[] votes;

    void newQuestion(const ref Question question){
        votes = new int[question.answers.length];
    }

}

@safe struct StreamListeners {
    alias StreamType = ReturnType!((HTTPServerResponse res){ return res.bodyWriter;});
        //vibe.internal.interfaceproxy.InterfaceProxy!(vibe.core.stream.OutputStream);
    StreamType[] outputStreams;

    void addStream(StreamType stream){
        outputStreams ~= stream;
    }

    void sendMessage(string message){
        bool[const(StreamType)] toDelete;
        foreach(stream ; outputStreams){
            try {

            } catch(Exception ex){
                logInfo("exception in sendMessage");
                logInfo(ex.msg);
                toDelete[stream] = true;
            }
        }

        if(toDelete.length > 0){
            //this is considered unsafe for some reason?
            outputStreams = outputStreams.remove!(x => x in toDelete);
        }
    }

}

void main()
{

    import std.file: readText;

    Question currentQuestion;
    PollResults results;

    const adminHtml = readText("svelte-frontend/dist/admin.html");
    const userHtml = readText("svelte-frontend/dist/index.html");


    auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1", "0.0.0.0", "::"];
    settings.accessLogToConsole = true;


    auto router = new URLRouter;
    router.get("/", (req, res){
            logInfo("calling serveIndex");
            logInfo(req.clientAddress.toAddressString());
            res.contentType = "text/html";
            if(isLocalhost(req.clientAddress)){
                logInfo("for admin");
                //res.render!("admin.dt");
                res.writeBody(adminHtml);
            } else {
                logInfo("for normal user");
                //res.render!("index.dt");
                res.writeBody(userHtml);
            }
        });

    router.get("/qrCode", (res, resp){
        sendJoinQRCode(res, resp, settings.port);
    });


    router.post("/updateQuestion", (res, resp){
            if(isLocalhost(res.clientAddress)){
                updateQuestion(res, resp, results, currentQuestion);
            } else {
                resp.statusCode = 403;
                resp.writeBody("only admin can update the question");
            }
        });

    router.get("/eventStream", &eventStream);

    //router.get("*", serveStaticFiles("./public"));
    //Normal user could theoretically access the admin HTML, but I don't think
    //that's any sort of vulnerability since the updateQuestion endpoint is protected
    router.get("*", serveStaticFiles("./svelte-frontend/dist"));

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
        case AddressFamily.UNIX:
            return true;
        case AddressFamily.INET:
            const addr4 = ntohl(address.sockAddrInet4.sin_addr.s_addr);
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

    //TODO add text to the bottom of the QR Code

    res.contentType = "image/svg+xml";
    res.writeBody(svgString);

}

void updateQuestion(HTTPServerRequest req, HTTPServerResponse res, ref PollResults results, out Question currentQuestion) @safe{
    if("questionText" !in req.form){
        res.statusCode = 400;
        res.writeBody("missing question text");
        return;
    }

    auto lines = req.form["questionText"].split("\n");
    if(lines.empty){
        lines = ["no question provided"];
    }
    auto question = Question(lines.front, lines[1 .. $]);
    const startPolling = "startPolling" in req.form && req.form["startPolling"];
    if(startPolling){
        currentQuestion = question;
        resetPolling(results, question);
    }
    question.toHTML(res);

}

void resetPolling(ref PollResults results, const ref Question question) @safe{
    results.newQuestion(question);
}
