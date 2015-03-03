using aroop;
using shotodol;
using shotodol.web;
using shotodol.signaling;

/** \addtogroup web
 *  @{
 */

internal class shotodol.web.HTTPRequestSink : OutputStream {
	bool closed;
	internal Queue<xtring>packets;
	internal static OutputStream?sink;
	PacketDisassembler?signalDecoder;
	public HTTPRequestSink() {
		packets = Queue<xtring>();
		closed = false;
		sink = null;
		signalDecoder = null;
	}
	~HTTPRequestSink() {
		sink = null;
	}

	public int process() {

		xtring?pkt = packets.dequeue();	
		if(pkt == null)
			return 0;

		if(signalDecoder == null)
			return 0;

		// do late initialization here ..
		BagFactory? bagBuilder = null;
		extring ex = extring.set_static_string("bag/factory");
		PluginManager.acceptVisitor(&ex, (x) => {
			bagBuilder = (BagFactory)x.getInterface(null);
		});
		if(bagBuilder == null) {
			Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.ERROR, 0, 80, "No bag factory\n");
			//print("Could not get bag factory\n");
			// fatal error
			core.assert(false);
			//return -1;
		}
		Bag?memory = bagBuilder.createBag(1024);
		core.assert(memory != null);
		//httpRequestProcessor x = httpRequestProcessor(memory);
#if HTTP_HEADER_DEBUG
		print("Processing %d data\n", pkt.fly().length());
#endif
		aroop_uword16 token = 0;
		token = pkt.fly().char_at(0);
		token = token << 8;
		token |= pkt.fly().char_at(1);
		pkt.fly().shift(2);
		//return x.processPacket(pkt);
		extring url = extring();
		int response = signalDecoder.parse(&url, memory, pkt);
		if(response == 0) {
			notifyPageHook(token, &url, memory);
		}
		return response;
	}

	void notifyPageHook(int token, extring*url, Bag header) {
		extring page = extring.stack(url.length()+8);
		page.concat_string("page/");
		page.concat(url);
#if HTTP_HEADER_DEBUG
		print("Knocking %s\n", page.to_string());
#endif
		extring status = extring();
		extring headerXtring = extring();
		header.getContentAs(&headerXtring);
		PluginManager.swarm(&page, &headerXtring, &status);
		if(sink == null)
			return;
#if false
		OutputStream xsink = sink.getOutputStream(token);
		if(xsink == null) {
			Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.ERROR, 0, 80, "No connection found\n");
			return;
		}
#endif
		extring pkt = extring();
		pkt.rebuild_in_heap(1024<<4);
		uchar tag = (uchar)((token>>8) & 0x0F);
		pkt.concat_char(tag);
		tag = (uchar)(token & 0x0F);
		pkt.concat_char(tag);
		pkt.concat_string("HTTP/1.1 200 OK\r\n");
		pkt.concat_string("Server:Shotodol Web 0.0.0\r\n");
		extring dlg = extring.stack(64);
		dlg.printf("Content-length:%d\r\n", status.length());
		pkt.concat(&dlg);
		pkt.concat_string("\r\n\r\n");
		// XXX we are coping content here
		pkt.concat(&status);
		Watchdog.watchit(core.sourceFileName(), core.sourceLineNo(), 10, Watchdog.WatchdogSeverity.LOG, 0, 80, &dlg);
		sink.write(&pkt);
		//sink.write(&status);
	}

	public override int write(extring*buf) throws IOStreamError.OutputStreamError {
		if(closed)
			return 0;
#if HTTP_HEADER_DEBUG
		print("Processor is reading data %d .. \n", buf.length());
#endif
		int len = buf.length();
		xtring pkt = new xtring.copy_on_demand(buf);
		packets.enqueue(pkt);
		process();
		return len;
	}

	public override void close() throws IOStreamError.OutputStreamError {
		closed = true;
	}
	internal int rehashHook(extring*inmsg, extring*outmsg) {
		sink = null;
		extring entry = extring.set_static_string("http/connectionoriented/output/sink");
		PluginManager.acceptVisitor(&entry, (x) => {
			sink = (OutputStream)x.getInterface(null);
		});
		signalDecoder = null;
		entry.rebuild_and_set_static_string("http/signaldecoder");
		PluginManager.acceptVisitor(&entry, (x) => {
			signalDecoder = (PacketDisassembler)x.getInterface(null);
		});
		return 0;
	}
}


/* @} */
