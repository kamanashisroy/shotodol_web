using aroop;
using shotodol;
using shotodol.http_gateway;

/***
 * \addtogroup http_gateway
 * @{
 */
internal class shotodol.http_gateway.HTTPPacketSorterServer : HTTPPacketSorterSpindle {
	OutputStream?sink;
	shotodol_platform_net.NetStreamPlatformImpl server = shotodol_platform_net.NetStreamPlatformImpl();
	CompositeOutputStream responders;
	enum serverInfo {
		TOKEN = 1024,
	}
	public HTTPPacketSorterServer(CompositeOutputStream givenResponders) {
		base();
		server = shotodol_platform_net.NetStreamPlatformImpl();
		server.setToken(serverInfo.TOKEN);
		sink = null;
		responders = givenResponders;
	}

	~HTTPPacketSorterServer() {
		server.close();
	}

	public void close() {
		cancel();
		pl.remove(&server);
		server.close();
	}

	public override int start(Spindle?plr) {
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Sync listening spindle starts!");
		extring addr = extring.set_static_string("TCP://127.0.0.1:81");
		setup(&addr);
		return 0;
	}

	int setup(extring*addr) {
		// TODO in place of shotodol_platform_net use abstraction to decouple from the implementation platform
		extring wvar = extring.set_static_string("HTTP server");
		Watchdog.watchvar(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, &wvar, addr);
		extring sockaddr = extring.stack(128);
		sockaddr.concat(addr);
		//sockaddr.trim_to_length(23);
		sockaddr.zero_terminate();
		int ret = server.connect(&sockaddr, shotodol_platform_net.ConnectFlags.BIND);
		sockaddr.destroy();
		if(ret == 0) {
			Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Listening");
			pl.add(&server);
			poll = true;
		}
		return ret;
	}

	int closeClient(aroop_uword16 token) {
#if HTTP_HEADER_DEBUG
		print("Closing client \n");
#endif
		if(sink == null)
			return -1;
		HTTPResponseSink client = (HTTPResponseSink)responders.getOutputStream(token);
		pl.remove(&client.client);
		return 0;
	}

	int acceptClient() {
		// accept client
#if HTTP_HEADER_DEBUG
		print("Accepting new client \n");
#endif
		HTTPResponseSink wsink = new HTTPResponseSink();
		wsink.client.accept(&server);
		pl.add(&wsink.client);
		aroop_uword16 token = responders.addOutputStream(wsink);
		print("New conenction token :%d\n", token);
		wsink.client.setToken(token);
		
		return 0;
	}

	internal override int onEvent(shotodol_platform_net.NetStreamPlatformImpl*x) {
		aroop_uword16 token = x.getToken();
		if(token == serverInfo.TOKEN) {
#if HTTP_HEADER_DEBUG
			print("[ ~ ] New client\n");
#endif
			acceptClient();
			return -1;
		}
#if HTTP_HEADER_DEBUG
		print("[ + ] Incoming data\n");
#endif
		xtring pkt = new xtring.alloc(1024/*, TODO set factory */);
		extring softpkt = extring.copy_on_demand(pkt);
		softpkt.shift(2); // keep space for 2 bytes of token header
		int len = x.read(&softpkt);
		if(len == 0) {
			return closeClient(token);
		}
		len+=2;
		pkt.fly().setLength(len);
#if HTTP_HEADER_DEBUG
		print("trimmed packet to %d data\n", pkt.fly().length());
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Reading ..");
#endif
		// IMPORTANT trim the pkt here.
		pkt.shrink(len);
#if HTTP_HEADER_DEBUG
		print("Read %d bytes from %d connection\n", len-2, token);
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Read bytes ..");
#endif
		if(sink == null) {
			return 0;
		}
		uchar ch = (uchar)((token >> 8) & 0xFF);
		pkt.fly().set_char_at(0, ch);
		ch = (uchar)(token & 0xFF);
		pkt.fly().set_char_at(1, ch);
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Writing to sink");
		sink.write(pkt);
		return 0;
	}
	internal int rehashHook(extring*inmsg, extring*outmsg) {
		sink = null;
		extring entry = extring.set_static_string("http/request/sink");
		Plugin.acceptVisitor(&entry, (x) => {
			sink = (OutputStream)x.getInterface(null);
		});
		return 0;
	}
}

/** @} */
