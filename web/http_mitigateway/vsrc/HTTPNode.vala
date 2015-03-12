using aroop;
using shotodol;
using shotodol.netio;
using shotodol.activeio;
using shotodol.distributedio;
using shotodol.fork;
using shotodol.http_mitigateway;

/** \addtogroup http_mitigateway
 *  @{
 */

internal struct shotodol.http_mitigateway.HTTPNode {
	public ForkStream?down; /* write down to child */
	public ForkStream?up; /* Read from child */
	public unowned HTTPMitigatewayModule?mod;
	public bool isParent;
	public int pindex;
	public extring mitikey;
	HTTPNode(HTTPMitigatewayModule?givenMod) {
		mitikey = extring.set_static_string("httpmitigate");
		down = null;
		up = null;
		mod = givenMod;
		pindex = 0;
		isParent = true;
	}
	internal int onFork_Before(extring*msg, extring*output) {
		if(msg == null || !msg.equals(&mitikey))
			return 0;
		if(!isParent)
			return 0;
		pindex++;
		down = new ForkStream();
		down.onFork_Before();
		up = new ForkStream();
		up.onFork_Before();
		return 0;
	}

	internal int onFork_After_prepare_pipe() {
		/* Child Pipe is required */
		if(down == null)
			return -1;
		down.onFork_After(!isParent);
		up.onFork_After(!isParent);
		return 0;
	}
	internal int cleanup_pipe() {
		up = null;
		down = null;
		return 0;
	}
}
