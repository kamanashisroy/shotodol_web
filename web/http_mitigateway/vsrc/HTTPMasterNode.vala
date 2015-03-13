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

internal struct shotodol.http_mitigateway.HTTPMasterNode {
	public HTTPNode node;
	RoundRobinPacketSorter sorter;
	ConnectionOrientedPacketConveyorBelt?server;
	CompositePullSingleFeedFiber?loadBalancingMasterFiber;
	HTTPMasterNode(HTTPMitigatewayModule?given) {
		node = HTTPNode(given);
		sorter = new RoundRobinPacketSorter(4);
		server = null;
		loadBalancingMasterFiber = null;
	}
	internal void cleanup() {
		if(loadBalancingMasterFiber != null) {
			print("-------- canceling fiber \n");
			loadBalancingMasterFiber.cancel();
			print("-------- done \n");
			loadBalancingMasterFiber = null;
		}

		// close the listening servers.
		if(server != null) {
			server.close(); // XXX should we close it ?
			server = null;
		}
		// cleanup sorter, sorter resides in parent not in child
		sorter = null;
	}
	internal int onFork_After_Parent(extring*msg, extring*output) {
		if(!node.isParent)
			return 0;
		/* It is forked only if it is for mitigateway, so filter mitikey */
		if(msg == null || !msg.equals(&node.mitikey))
			return 0;

		print("-------- Master is checking the fiber\n");
		// --------------------------------------------
		// Prepare parent fiber -----------------------
		// --------------------------------------------
		if(loadBalancingMasterFiber == null) {
			loadBalancingMasterFiber = new CompositePullSingleFeedFiber();
			extring parentName = extring.set_static_string("Collect data from children, and send through network\n");
			loadBalancingMasterFiber.setName(&parentName);
			extring entry = extring.set_static_string("MainFiber");
			PluginManager.register(&entry, new AnyInterfaceExtension(loadBalancingMasterFiber, node.mod));
		}
		// --------------------------------------------


		print("-------- master is preparing pipe\n");
		// --------------------------------------------
		// Child output stream is "down" stream -------
		// --------------------------------------------
		/* Child Pipe is required */
		if(node.onFork_After_prepare_pipe() != 0) {
			Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.ERROR, 0, 80, "Fork completion error: no down(to child) pipe found\n");
			return -1;
		}

		print("-------- master is name output stream\n");
		// name it ------------------------------------
		OutputStream os = node.down.getOutputStream();
		extring childName = extring.stack(128);
		childName.printf("Output to child %d", node.pindex);
		os.setName(&childName);

		// sorter outputs to child --------------------
		sorter.addOutputStream(os);


		// --------------------------------------------
		// Child output stream is "down" stream -------
		// --------------------------------------------
		node.up.onFork_After();

		// Name it ------------------------------------
		InputStream is = node.up.getInputStream();
		childName.printf("Input from child %d", node.pindex);
		is.setName(&childName);

		// Read/Pull by Composite puller --------------
		loadBalancingMasterFiber.pull(is);
		// --------------------------------------------

		// cleanup ------------------------------------
		node.cleanup_pipe();
		// --------------------------------------------
		print("-------- master rehashing\n");
		rehashParent(null);
		return 0;
	}

	internal int rehashParent(OutputStream?lbsink) {
		if(loadBalancingMasterFiber == null) {
			return 0;
		}
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 80, "Rehashing parent process\n");
		if(lbsink == null)
			Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.ERROR, 0, 80, "No outgoing sink found up to browser\n");
		loadBalancingMasterFiber.feed(lbsink);
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 80, "Set\n");
		return 0;
	}
	void setupServer(ConfigEngine?cfg) {
		// get the server address from config
		
		extring laddr = extring.set_static_string("TCP://127.0.0.1:82");
		if(cfg != null) {
			extring nm = extring.set_string(core.sourceModuleName());
			extring grp = extring.set_static_string("server");
			extring key = extring.set_static_string("address");
			cfg.getValueAs(&nm,&grp,&key,&laddr);
		}
		extring stack = extring.set_static_string("http/mitigateway");
		server = new ConnectionOrientedPacketConveyorBelt(&stack, &laddr);
	}
	internal int setup(ConfigEngine?cfg) {
		setupServer(cfg);
		server.registerAllHooks(node.mod);
		//PluginManager.register(&entry, new HookExtension(onQuit, node.mod));
		extring entry = extring.set_static_string("http/mitigateway/connectionoriented/incoming/sink");
		PluginManager.register(&entry, new AnyInterfaceExtension(sorter, node.mod));
		sorter.setName(&entry);
		server.rehashHook(null,null);
		return 0;
	}
	internal int onQuit(extring*msg, extring*output) {
		cleanup();
		return 0;
	}
}
