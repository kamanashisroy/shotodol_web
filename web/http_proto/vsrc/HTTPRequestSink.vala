using aroop;
using shotodol;
using shotodol.web;

/** \addtogroup web
 *  @{
 */
public enum shotodol.web.httpRequest {
	REQUEST_METHOD = 1,
	REQUEST_URL,
	REQUEST_VERSION,
	REQUEST_KEY,
	REQUEST_VALUE,
	REQUEST_QUERY_KEY,
	REQUEST_QUERY_VALUE,
}
internal class shotodol.web.HTTPRequestSink : OutputStream {
	struct httpRequestProcessor {
		protected Bundler bndlr;
		Renu?header;
		int lineNumber;
		extring url;
		extring colonSign;
		aroop_uword16 token;
		protected httpRequestProcessor(Renu?memory) {
			colonSign = extring.set_static_string(":");
			bndlr = Bundler();
			lineNumber = 0;
			url = extring();
			core.assert(memory != null);
			header = memory;
			bndlr.buildFromCarton(&header.msg, header.size, BundlerAffixes.PREFIX, 24);
			token = 0;
		}
		int readLineAs(extring*input, extring*ln) {
			ln.destroy();
			int i = 0;
			int ln_start = 0;
			int retlen = 0;
			for(i=0;i<input.length();i++) {
				if(input.char_at(i) == '\n') {
					if(i - ln_start == 0) {
						// skip blank line
						ln_start++;
						continue;
					}
					ln.rebuild_and_copy_shallow(input);
					//ln.skip(i);
					ln.trim_to_length(i);
					retlen = i - ln_start;
					if(ln_start != 0) {
						ln.shift(ln_start);
					}
					ln_start = i+1;
					input.shift(ln_start);
#if HTTP_HEADER_DEBUG
					extring dlg = extring.stack(ln.length()+1);
					dlg.concat(ln);
					dlg.concat_char('\0');
					print("parsed line %s\n", dlg.to_string());
#endif
					break;
				}
			}
			return 0;
		}

		void parseQueryString() {
			extring queryString = extring();
			int i = 0;
			for(i = 0;i < url.length();i++) {
				if(url.char_at(i) == '?') {
					queryString.rebuild_and_copy_shallow(&url);
					url.trim_to_length(i);
					queryString.shift(i+1);
					break;
				}
			}
			extring strtoken = extring();
			extring queryDelimiters = extring.set_static_string("=&");
			while(true) {
				if(queryString.is_empty())
					break;
				LineAlign.next_token_delimitered(&queryString, &strtoken, &queryDelimiters);
				if(!strtoken.is_empty() && (strtoken.char_at(0) == '&' || strtoken.char_at(0) == '=')) {
					strtoken.shift(1);
					continue;
				}
				if(queryString.is_empty() || queryString.char_at(0) == '&') {
#if HTTP_HEADER_DEBUG
					print("value[%d,%d]:%s\n", strtoken.length(), queryString.length(), strtoken.to_string());
#endif
					bndlr.writeEXtring(httpRequest.REQUEST_QUERY_VALUE, &strtoken);
				} else {
#if HTTP_HEADER_DEBUG
					print("key[%d,%d]:%s\n", strtoken.length(), queryString.length(), strtoken.to_string());
#endif
					bndlr.writeEXtring(httpRequest.REQUEST_QUERY_KEY, &strtoken);
				}
			}
		}

		void notifyPageHook() {
			extring page = extring.stack(url.length()+8);
			page.concat_string("page/");
			page.concat(&url);
#if HTTP_HEADER_DEBUG
			print("Knocking %s\n", page.to_string());
#endif
			extring status = extring();
			extring headerXtring = extring();
			header.getTaskAs(&headerXtring);
			Plugin.swarm(&page, &headerXtring, &status);
			if(sink == null)
				return;
			OutputStream xsink = sink.getOutputStream(token);
			if(xsink == null) {
				Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.ERROR, 0, 0, "No connection found\n");
				return;
			}
			extring pkt = extring();
			pkt.rebuild_in_heap(512);
			pkt.concat_string("HTTP/1.1 200 OK\r\n");
			pkt.concat_string("Server:Shotodol Web 0.0.0\r\n");
			extring dlg = extring.stack(64);
			dlg.printf("Content-length:%d\r\n", status.length());
			pkt.concat(&dlg);
			pkt.concat_string("\r\n\r\n");
			xsink.write(&pkt);
			xsink.write(&status);
		}

		void parseFirstLine(extring*cmd) {
			extring strtoken = extring();
			LineAlign.next_token(cmd, &strtoken);
			bndlr.writeEXtring(httpRequest.REQUEST_METHOD, &strtoken);
			LineAlign.next_token(cmd, &strtoken);
			bndlr.writeEXtring(httpRequest.REQUEST_URL, &strtoken);
			bndlr.writeEXtring(httpRequest.REQUEST_VERSION, cmd);
			url.rebuild_in_heap(strtoken.length()+1);
			url.concat(&strtoken);
			lineNumber++;
			if(url.char_at(0) == '/')
				url.shift(1);
			parseQueryString();
			if(url.length() == 0)
				url.rebuild_and_set_static_string("index");
		}

		void parseLine(extring*cmd) {
			if(lineNumber == 0) {
				parseFirstLine(cmd);
				return;
			}
			cmd.zero_terminate();
			extring strtoken = extring();
			LineAlign.next_token_delimitered(cmd, &strtoken, &colonSign);
			if(cmd.char_at(0) == '=') {
				bndlr.writeEXtring(httpRequest.REQUEST_KEY, &strtoken);
				bndlr.writeEXtring(httpRequest.REQUEST_VALUE, cmd);
			}
			lineNumber++;
		}

		public int processPacket(extring*pkt) {
			extring ln = extring();	
			token = pkt.char_at(0);
			token = token << 8;
			token |= pkt.char_at(1);
			pkt.shift(2);
#if HTTP_HEADER_DEBUG
			extring pkt_var = extring.set_static_string("Packet");
			Watchdog.watchvar(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, &pkt_var, pkt);
			extring dlg = extring.stack(128);
			dlg.printf("%d,%s,%d,%s", token, pkt_var.to_string(), pkt.length(), pkt.to_string());
			Watchdog.watchit(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 0, &dlg);
#endif
			while(true) {
				readLineAs(pkt, &ln);
				if(!ln.is_empty()) {
					parseLine(&ln);
				} else {
#if HTTP_HEADER_DEBUG
					print("End of header\n");
#endif
					header.finalize(&bndlr);
					// Say that this request will not process any packet
					notifyPageHook();
					break;
				}
			}
			return 0;
		}
	}
	bool closed;
	internal Queue<xtring>packets;
	internal static CompositeOutputStream?sink;
	public HTTPRequestSink() {
		packets = Queue<xtring>();
		closed = false;
		sink = null;
	}
	~HTTPRequestSink() {
		sink = null;
	}

	public int process() {

		xtring?pkt = packets.dequeue();	
		if(pkt == null)
			return 0;

		// do late initialization here ..
		RenuFactory? renuBuilder = null;
		extring ex = extring.set_static_string("renu/factory");
		Plugin.acceptVisitor(&ex, (x) => {
			renuBuilder = (RenuFactory)x.getInterface(null);
		});
		if(renuBuilder == null) {
			print("Could not get renu factory\n");
			// fatal error
			core.assert(false);
			//return -1;
		}
		Renu?memory = renuBuilder.createRenu(1024);
		core.assert(memory != null);
		httpRequestProcessor x = httpRequestProcessor(memory);
#if HTTP_HEADER_DEBUG
		print("Processing %d data\n", pkt.fly().length());
#endif
		return x.processPacket(pkt);
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
		Plugin.acceptVisitor(&entry, (x) => {
			sink = (CompositeOutputStream)x.getInterface(null);
		});
		return 0;
	}
}


/* @} */
