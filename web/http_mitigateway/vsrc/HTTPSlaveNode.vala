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

internal struct shotodol.http_mitigateway.HTTPSlaveNode {
	public HTTPMasterNode master;
	PullFeedFiber?slaveFiber;
	HTTPSlaveNode(HTTPMitigatewayModule?given) {
		master = HTTPMasterNode(given);
		slaveFiber = null;
	}
	internal int onFork_After_Child(extring*msg, extring*output) {
		master.node.isParent = false;
		/* It is forked only if it is for mitigateway, so filter mitikey */
		if(msg == null || !msg.equals(&master.node.mitikey)) {
			print("-------- Child process is inactive as http slave\n");
			return 0;
		}

		print("-------- prepare pipes for communication\n");
		// --------------------------------------------
		// Prepare pipes for communication ------------
		// --------------------------------------------
		if(master.node.onFork_After_prepare_pipe() != 0)
			return -1;
		// --------------------------------------------

		print("-------- cleanup master\n");
		// --------------------------------------------
		// Cleanup master 
		// --------------------------------------------
		master.cleanup();
		// --------------------------------------------

		print("-------- prepare child fiber\n");
		// --------------------------------------------
		// Prepare child fiber ------------------------
		// --------------------------------------------
		if(slaveFiber != null) { // slaveFiber cannot be defined already
			return -1;
		}

		print("-------- read from master \n");
		// Read from parent and feed incoming/sink ----
		InputStream is = master.node.down.getInputStream();
		extring readName = extring.stack(128);
		readName.printf("Input from parent in child %d", master.node.pindex);
		is.setName(&readName);

		print("-------- read through fiber \n");
		// Read from parent and feed incoming/sink ----
		slaveFiber = new PullFeedFiber(is, null);


		print("-------- register fiber \n");
		// register -----------------------------------
		extring entry = extring.set_static_string("MainFiber");
		PluginManager.register(&entry, new AnyInterfaceExtension(slaveFiber, master.node.mod));
		// --------------------------------------------


		print("-------- register child sink \n");
		// --------------------------------------------
		// Map child output to http output ------------
		// --------------------------------------------
		extring childName = extring.stack(128);
		OutputStream os = master.node.up.getOutputStream();
		entry.rebuild_and_set_static_string("http/connectionoriented/outgoing/sink");
		childName.printf("Output to parent ");
		childName.concat(&entry);
		PluginManager.register(&entry, new AnyInterfaceExtension(os, master.node.mod));
		// --------------------------------------------

		print("-------- rehash child for the first time\n");
		onRehash(null, null);
		
		print("-------- cleanup pipstreams ..\n");
		// cleanup ------------------------------------
		master.node.cleanup_pipe();
		// --------------------------------------------
		return 0;
	}

	internal int onRehash(OutputStream?hsink, OutputStream?lbSink) {
		if(master.node.isParent) {
			return master.rehashParent(lbSink);
		}
		if(slaveFiber == null) { // slaveFiber cannot be null
			return -1;
		}
		slaveFiber.feed(hsink);
		return 0;
	}
	internal void destroy() {
		master.cleanup();
		slaveFiber.cancel();
		slaveFiber = null;
	}
}
