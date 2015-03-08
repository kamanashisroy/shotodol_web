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
internal class shotodol.http_mitigateway.HTTPLoadBalancerCommand : M100Command {
	RoundRobinPacketSorter sorter;
	ForkStream?down;
	ForkStream?up;
	ConnectionOrientedPacketConveyorBelt?server;
	unowned HTTPMitigatewayModule?mod;
	PullFeedFiber?childFiber;
	CompositePullSingleFeedFiber?parentFiber;
	bool isParent;
	extring mitikey;
	enum Options {
		CHILD_COUNT = 1,
	}
	int childIndex;
	public HTTPLoadBalancerCommand(HTTPMitigatewayModule?givenMod) {
		mitikey = extring.set_static_string("httpmitigate");
		base(&mitikey);
		sorter = new RoundRobinPacketSorter(4);
		server = null;
		down = null;
		up = null;
		mod = givenMod;
		isParent = true;
		childFiber = null;
		parentFiber = null;
		addOptionString("-child", M100Command.OptionType.INT, Options.CHILD_COUNT, "Number of child process to fork");
		childIndex = 0;
	}
	~HTTPLoadBalancerCommand() {
		mitikey.destroy();
	}
	public override int act_on(extring*cmdstr, OutputStream pad, M100CommandSet cmds) throws M100CommandError.ActionFailed {
		ArrayList<xtring> vals = ArrayList<xtring>();
		if(parseOptions(cmdstr, &vals) != 0) {
			throw new M100CommandError.ActionFailed.INVALID_ARGUMENT("Invalid argument");
		}
		if(!isParent || server != null) // sanity check
			return 0;
		int childCount = 4;
		// TODO show the available down children and show the current load ..
		xtring? arg = vals[Options.CHILD_COUNT];
		if(arg != null)
			childCount = arg.fly().to_int();
		// spawn processes
		int i = 0;
		extring forkHook = extring.set_static_string("fork");
		for(i = 0; i < childCount; i++) {
			PluginManager.swarm(&forkHook, &mitikey, null);
			if(!isParent)
				return 0;
		}
		setup();
		rehashParent();
		return 0;
	}
	void setupServer() {
		// get the server address from config
		ConfigEngine?cfg = null;
		extring entry = extring.set_static_string("config/server");
		PluginManager.acceptVisitor(&entry, (x) => {
			cfg = (ConfigEngine)x.getInterface(null);
		});
		
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
	int setup() {
		setupServer();
		server.registerAllHooks(mod);
		extring entry = extring.set_static_string("onQuit/soft");
		PluginManager.register(&entry, new HookExtension(onQuitHook, mod));
		entry.rebuild_and_set_static_string("http/mitigateway/connectionoriented/incoming/sink");
		PluginManager.register(&entry, new AnyInterfaceExtension(sorter, mod));
		sorter.setName(&entry);
		server.rehashHook(null,null);
		return 0;
	}
	internal int onFork_Before(extring*msg, extring*output) {
		if(msg == null || !msg.equals(&mitikey))
			return 0;
		if(!isParent)
			return 0;
		/*if(server == null)
			return 0;*/
		childIndex++;
		down = new ForkStream();
		down.onFork_Before();
		up = new ForkStream();
		up.onFork_Before();
		return 0;
	}
	internal int onFork_After_Parent(extring*msg, extring*output) {
		/* It is forked only if it is for mitigateway, so filter mitikey */
		if(msg == null || !msg.equals(&mitikey))
			return 0;

		/* Child Pipe is required */
		if(down == null)
			return -1;

		down.onFork_After(false);

		// --------------------------------------------
		// sorter outputs to child --------------------
		// --------------------------------------------
		OutputStream os = down.getOutputStream();
		extring childName = extring.stack(128);
		childName.printf("Output to child %d", childIndex);
		os.setName(&childName);
		sorter.addOutputStream(os);
		// --------------------------------------------


		down = null;
		up.onFork_After(false);
		if(parentFiber == null) {
			parentFiber = new CompositePullSingleFeedFiber();
			extring entry = extring.set_static_string("MainFiber");
			PluginManager.register(&entry, new AnyInterfaceExtension(parentFiber, mod));
		}


		// --------------------------------------------
		// Read/Pull by Composite puller --------------
		// --------------------------------------------
		InputStream is = up.getInputStream();
		childName.printf("Input from child %d", childIndex);
		is.setName(&childName);
		parentFiber.pull(is);
		// --------------------------------------------

		up = null;
		rehashParent();
		return 0;
	}
	internal int onFork_After_Child(extring*msg, extring*output) {
		/* It is forked only if it is for mitigateway, so filter mitikey */
		if(msg == null || !msg.equals(&mitikey))
			return 0;

		/* Child Pipe is required */
		if(down == null)
			return -1;

		isParent = false;
		down.onFork_After(true);
		up.onFork_After(true);
		// close the listening servers.
		//if(server != null)server.close(); // XXX should we close it ?

		// --------------------------------------------
		// Map child output to http output ------------
		// --------------------------------------------
		extring childName = extring.stack(128);
		OutputStream os = up.getOutputStream();
		extring entry = extring.set_static_string("http/connectionoriented/outgoing/sink");
		childName.printf("Output to parent ");
		childName.concat(&entry);
		PluginManager.register(&entry, new AnyInterfaceExtension(os, mod));
		// --------------------------------------------

		rehashChild();
		
		// cleanup sorter, sorter resides in parent not in child
		sorter = null;
		return 0;
	}
	int rehashParent() {
		OutputStream?lbsink = null;
		if(parentFiber == null) {
			return 0;
		}
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 80, "Rehashing\n");
		extring entry = extring.set_static_string("http/mitigateway/connectionoriented/outgoing/sink");
		PluginManager.acceptVisitor(&entry, (x) => {
			lbsink = (OutputStream)x.getInterface(null);
		});
		if(lbsink == null)
			Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.ERROR, 0, 80, "No outgoing sink found up to browser\n");
		parentFiber.feed(lbsink);
		Watchdog.watchit_string(core.sourceFileName(), core.sourceLineNo(), 3, Watchdog.WatchdogSeverity.LOG, 0, 80, "Set\n");
		return 0;
	}
	int rehashChild() {
		if(childFiber == null) { // register a childFiber
			// --------------------------------------------
			// Read from parent and feed incoming/sink ----
			// --------------------------------------------
			InputStream is = down.getInputStream();
			extring readName = extring.stack(128);
			readName.printf("Input from parent in child %d", childIndex);
			is.setName(&readName);
			childFiber = new PullFeedFiber(is, null);
			// --------------------------------------------


			extring entry = extring.set_static_string("MainFiber");
			PluginManager.register(&entry, new AnyInterfaceExtension(childFiber, mod));
			entry.destroy();
		}
		OutputStream?hsink = null;
		extring entry = extring.set_static_string("http/connectionoriented/incoming/sink");
		PluginManager.acceptVisitor(&entry, (x) => {
			hsink = (OutputStream)x.getInterface(null);
		});
		childFiber.feed(hsink);
		return 0;
	}
	internal int onRehash(extring*msg, extring*output) {
		if(isParent) {
			return rehashParent();
		}
		return rehashChild();
	}
	int onQuitHook(extring*msg, extring*output) {
		if(server != null)
			server.close();
		server = null;
		return 0;
	}
}
/* @} */
