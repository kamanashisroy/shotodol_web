using aroop;
using shotodol;
using shotodol.web;

/** \addtogroup web
 *  @{
 */
internal class shotodol.web.HTTPCompositeResponseSink : OutputStream {
	bool closed;
	//internal Queue<xtring>packets;
	Set<HTTPResponseSink> clients;
	public HTTPCompositeResponseSink() {
		//packets = Queue<xtring>();
		closed = false;
		clients = Set<HTTPResponseSink>();
		//lastActivityTime = 0;
		// TODO cleanup on last activity time
	}
	~HTTPCompositeResponseSink() {
		clients.destroy();
	}

	internal void addResponder(HTTPResponseSink responder) {
		//clients.add(responder);
		AroopPointer<HTTPResponseSink> ptr = clients.addPointer(responder);
		responder.client.setToken(ptr.get_token());
	}

	public override int write(extring*buf) throws IOStreamError.OutputStreamError {
		if(closed)
			return 0;
		int len = buf.length();
		if(len <= 2)
			return len;
		int token = buf.char_at(0);
		token = token << 8;
		token |= buf.char_at(1);
		buf.shift(2);
		AroopPointer<HTTPResponseSink>?ptr = clients.getByToken(token);
		if(ptr == null) 
			return -1;
		unowned HTTPResponseSink sink = ptr.getUnowned();
		return sink.write(buf) + 2;
	}

	public override void close() throws IOStreamError.OutputStreamError {
		closed = true;
	}
}


/* @} */
