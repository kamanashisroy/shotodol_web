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
	bool waiting;
	CompositeOutputStream responders;
	public HTTPPacketSorterServer(CompositeOutputStream givenResponders) {
		base();
		server = shotodol_platform_net.NetStreamPlatformImpl();
		sink = null;
		waiting = true;
		responders = givenResponders;
	}

	~HTTPPacketSorterServer() {
		server.close();
	}

	public void close() {
		cancel();
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

#if false
	int closeClient() {
#if HTTP_HEADER_DEBUG
		print("Closing client \n");
#endif
		pl.remove(&client);
		client.close();
		pl.add(&client);
		waiting = true;
		//poll = false;
		return 0;
	}
#endif

	int acceptClient() {
		// accept client
#if HTTP_HEADER_DEBUG
		print("Accepting new client \n");
#endif
		HTTPResponseSink wsink = new HTTPResponseSink();
		wsink.client.accept(&server);
		pl.add(&wsink.client);
		pl.remove(&server);
		aroop_uword16 token = responders.addOutputStream(wsink);
		wsink.client.setToken(token);
		
		//server.close();
		waiting = false;
		return 0;
	}

	internal override int onEvent(shotodol_platform_net.NetStreamPlatformImpl*x) {
#if HTTP_HEADER_DEBUG
		print("[ ~ ] Server\n");
#endif
		if(waiting) {
			acceptClient();
			return -1;
		}
		xtring pkt = new xtring.alloc(1024/*, TODO set factory */);
		extring softpkt = extring.copy_on_demand(pkt);
		softpkt.shift(2); // keep space for 2 bytes of header
		int len = x.read(&softpkt);
		pkt.fly().setLength(len+2);
#if HTTP_HEADER_DEBUG
		print("trimmed packet to %d data\n", pkt.fly().length());
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Reading ..");
#endif
		// IMPORTANT trim the pkt here.
		pkt.shrink(len);
#if HTTP_HEADER_DEBUG
		print("Read %d bytes\n", len);
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, "Read bytes ..");
#endif
		if(sink == null) {
			return 0;
		}
		uint token = x.getToken();
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
