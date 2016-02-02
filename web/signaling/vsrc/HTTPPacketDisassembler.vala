using aroop;
using shotodol;

/***
 * \addtogroup web.signaling
 * @{
 */
public enum shotodol.web.signaling.httpRequest {
REQUEST_METHOD = 1,
REQUEST_URL,
REQUEST_VERSION,
REQUEST_KEY,
REQUEST_VALUE,
REQUEST_QUERY_KEY,
REQUEST_QUERY_VALUE,
}
internal class shotodol.web.signaling.HTTPPacketDisassembler : shotodol.signaling.PacketDisassembler {
	extring colonSign;
	public HTTPPacketDisassembler() {
			colonSign = extring.set_static_string(":");
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
				ln.truncate(i);
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
	void parseQueryString(Bundler*bndlr, extring*url) {
		extring queryString = extring();
		int i = 0;
		for(i = 0;i < url.length();i++) {
			if(url.char_at(i) == '?') {
				queryString.rebuild_and_copy_shallow(url);
				url.truncate(i);
				queryString.shift(i+1);
				break;
			}
		}
		extring strtoken = extring();
		extring queryDelimiters = extring.set_static_string("=&");
		while(true) {
			if(queryString.is_empty())
				break;
			LineExpression.next_token_delimitered(&queryString, &strtoken, &queryDelimiters);
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


	void parseFirstLine(extring*url, Bundler*bndlr, extring*cmd) {
		extring strtoken = extring();
		LineExpression.next_token(cmd, &strtoken);
		bndlr.writeEXtring(httpRequest.REQUEST_METHOD, &strtoken);
		LineExpression.next_token(cmd, &strtoken);
		bndlr.writeEXtring(httpRequest.REQUEST_URL, &strtoken);
		bndlr.writeEXtring(httpRequest.REQUEST_VERSION, cmd);
		url.rebuild_in_heap(strtoken.length()+1);
		url.concat(&strtoken);
		if(url.char_at(0) == '/')
			url.shift(1);
		parseQueryString(bndlr, url);
		if(url.length() == 0)
			url.rebuild_and_set_static_string("index");
	}

	void parseLine(Bundler*bndlr, extring*cmd) {
		cmd.zero_terminate();
		extring strtoken = extring();
		LineExpression.next_token_delimitered(cmd, &strtoken, &colonSign);
		if(cmd.char_at(0) == '=') {
			bndlr.writeEXtring(httpRequest.REQUEST_KEY, &strtoken);
			bndlr.writeEXtring(httpRequest.REQUEST_VALUE, cmd);
		}
	}

	public override int parse(extring*outUrl, Bag?header, extring*pkt) {
		core.assert(header != null);
		Bundler bndlr = Bundler();
		bndlr.buildFromCarton(&header.msg, header.size, BundlerAffixes.PREFIX, 24);
		extring ln = extring();	
#if HTTP_HEADER_DEBUG
		extring pkt_var = extring.set_static_string("Packet");
		Watchdog.watchvar(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.Severity.LOG, 0, 0, &pkt_var, pkt);
		extring dlg = extring.stack(128);
		dlg.printf("%s,%d,%s", pkt_var.to_string(), pkt.length(), pkt.to_string());
		Watchdog.watchit(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.Severity.LOG, 0, 0, &dlg);
#endif
		bool firstLine = true;
		while(true) {
			readLineAs(pkt, &ln);
			if(!ln.is_empty()) {
				if(firstLine) {
					parseFirstLine(outUrl, &bndlr, &ln);
					firstLine = false;
				}
				parseLine(&bndlr, &ln);
			} else {
#if HTTP_HEADER_DEBUG
				print("End of header\n");
#endif
				header.finalize(&bndlr);
				// Say that this request will not process any packet
				// notifyPageHook();
				//break;
				return 0;
			}
		}
		return -1;
	}
}

/** @} */
