using aroop;
using shotodol;
using shotodol.http_gateway;

/**
 * \addtogroup http_gateway
 *  @{
 */
internal class shotodol.http_gateway.HTTPResponseSink : OutputStream {
	bool closed;
	internal Queue<xtring>packets;
	internal static OutputStream?sink;
	internal shotodol_platform_net.NetStreamPlatformImpl client;
	//long lastActivityTime;
	public HTTPResponseSink() {
		packets = Queue<xtring>();
		closed = false;
		sink = null;
		client = shotodol_platform_net.NetStreamPlatformImpl();
		//lastActivityTime = 0;
		// TODO cleanup on last activity time
	}
	~HTTPResponseSink() {
		sink = null;
		client.close();
	}

	public int process() {

		xtring?pkt = packets.dequeue();	
		if(pkt == null)
			return 0;
		return client.write(pkt);
	}


	public override int write(extring*buf) throws IOStreamError.OutputStreamError {
		if(closed)
			return 0;
		int len = buf.length();
		xtring pkt = new xtring.copy_on_demand(buf);
		packets.enqueue(pkt);
		process();
		return len;
	}

	public override void close() throws IOStreamError.OutputStreamError {
		closed = true;
	}
}


/* @} */
