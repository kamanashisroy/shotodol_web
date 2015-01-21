using aroop;
using shotodol;

/***
 * \addtogroup http.signaling
 * @{
 */
internal class shotodol.http.signaling.HTTPPacketDisassembler : shotodol.signaling.PacketDisassembler {
	public HTTPPacketDisassembler() {
	}
	public override int parse(Bag state, extring*pkt) {
#if false
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
#endif
		return 0;
	}
}

/** @} */
