using aroop;
using shotodol;
using shotodol.netio;
using shotodol.distributedio;
using shotodol.fork;
using shotodol.http_lbgateway;

/** \addtogroup http_lbgateway
 *  @{
 */
internal class shotodol.http_lbgateway.HTTPLoadBalancerCommand : M100Command {
	RoundRobinPacketSorter sorter;
	ForkStream?down;
	ForkStream?up;
	ConnectionOrientedPacketConveyorBelt?server;
	unowned HTTPLoadBalancerGatewayModule?mod;
	PullFeedSpindle?childSpindle;
	CompositePullSingleFeedSpindle?parentSpindle;
	bool isParent;
	public HTTPLoadBalancerCommand(HTTPLoadBalancerGatewayModule?givenMod) {
		var prefix = extring.set_static_string("httplb");
		base(&prefix);
		sorter = new RoundRobinPacketSorter(4);
		server = null;
		down = null;
		up = null;
		mod = givenMod;
		isParent = true;
		childSpindle = null;
		parentSpindle = null;
	}
	public override int act_on(extring*cmdstr, OutputStream pad, M100CommandSet cmds) {
		if(!isParent) // Do nothing in child process
			return 0;
		// TODO show the available down children and show the current load ..
		if(server != null)
			return 0;
		setup();
		// TODO fork ..
		return 0;
	}
	void setupServer() {
		// get the server address from config
		ConfigEngine?cfg = null;
		extring entry = extring.set_static_string("config/server");
		Plugin.acceptVisitor(&entry, (x) => {
			cfg = (ConfigEngine)x.getInterface(null);
		});
		
		extring laddr = extring.set_static_string("TCP://127.0.0.1:80");
		if(cfg != null) {
			extring nm = extring.set_string(core.sourceModuleName());
			extring grp = extring.set_static_string("server");
			extring key = extring.set_static_string("address");
			cfg.getValueAs(&nm,&grp,&key,&laddr);
		}
		extring stack = extring.set_static_string("httplb");
		server = new ConnectionOrientedPacketConveyorBelt(&stack, &laddr);
	}
	int setup() {
		print("Opening server\n");
		setupServer();
		server.registerAllHooks(mod);
		server.rehashHook(null,null);
		extring entry = extring.set_static_string("onQuit");
		Plugin.register(&entry, new HookExtension(onQuitHook, mod));
		entry.rebuild_and_set_static_string("httplb/connectionoriented/input/sink");
		Plugin.register(&entry, new AnyInterfaceExtension(sorter, mod));
		return 0;
	}
	internal int onFork_Before(extring*msg, extring*output) {
		if(!isParent)
			return 0;
		if(server == null)
			return 0;
		down = new ForkStream();
		down.onFork_Before();
		up = new ForkStream();
		up.onFork_Before();
		return 0;
	}
	internal int onFork_After_Parent(extring*msg, extring*output) {
		if(down == null)
			return -1;
		down.onFork_After(false);
		sorter.addSink(down.getOutputStream());
		down = null;
		up.onFork_After(false);
		if(parentSpindle == null) {
			parentSpindle = new CompositePullSingleFeedSpindle();
			extring entry = extring.set_static_string("MainSpindle");
			Plugin.register(&entry, new AnyInterfaceExtension(parentSpindle, mod));
		}
		parentSpindle.pull(up.getInputStream());
		up = null;
		rehashParent();
		return 0;
	}
	internal int onFork_After_Child(extring*msg, extring*output) {
		if(down == null)
			return -1;
		isParent = false;
		down.onFork_After(true);
		up.onFork_After(true);
		// close the listening servers.
		server.close();
		extring entry = extring.set_static_string("http/connectionoriented/output/sink");
		Plugin.register(&entry, new AnyInterfaceExtension(up.getOutputStream(), mod));
		rehashChild();
		sorter = null;
		return 0;
	}
	int rehashParent() {
		OutputStream?lbsink = null;
		if(parentSpindle == null)
			return 0;
		extring entry = extring.set_static_string("httplb/connectionoriented/output/sink");
		Plugin.acceptVisitor(&entry, (x) => {
			lbsink = (OutputStream)x.getInterface(null);
		});
		parentSpindle.feed(lbsink);
		return 0;
	}
	int rehashChild() {
		if(childSpindle == null) { // register a childSpindle
			childSpindle = new PullFeedSpindle(down.getInputStream(), null);
			extring entry = extring.set_static_string("MainSpindle");
			Plugin.register(&entry, new AnyInterfaceExtension(childSpindle, mod));
			entry.destroy();
		}
		OutputStream?hsink = null;
		extring entry = extring.set_static_string("http/connectionoriented/input/sink");
		Plugin.acceptVisitor(&entry, (x) => {
			hsink = (OutputStream)x.getInterface(null);
		});
		childSpindle.feed(hsink);
		return 0;
	}
	internal int onRehash(extring*msg, extring*output) {
		if(server == null)
			return 0;
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
