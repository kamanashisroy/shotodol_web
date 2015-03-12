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
	enum Options {
		CHILD_COUNT = 1,
	}
	HTTPSlaveNode node;
	public HTTPLoadBalancerCommand(HTTPMitigatewayModule?givenMod) {
		node = HTTPSlaveNode(givenMod);
		base(&node.master.node.mitikey);
		addOptionString("-child", M100Command.OptionType.INT, Options.CHILD_COUNT, "Number of child process to fork");
	}
	~HTTPLoadBalancerCommand() {
		node.destroy();
	}
	public override int act_on(extring*cmdstr, OutputStream pad, M100CommandSet cmds) throws M100CommandError.ActionFailed {
		ArrayList<xtring> vals = ArrayList<xtring>();
		if(parseOptions(cmdstr, &vals) != 0) {
			throw new M100CommandError.ActionFailed.INVALID_ARGUMENT("Invalid argument");
		}
		if(!node.master.node.isParent || node.master.server != null) // sanity check
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
			PluginManager.swarm(&forkHook, &node.master.node.mitikey, null);
			if(!node.master.node.isParent)
				return 0;
		}
		ConfigEngine?cfg = null;
		extring entry = extring.set_static_string("config/server");
		PluginManager.acceptVisitor(&entry, (x) => {
			cfg = (ConfigEngine)x.getInterface(null);
		});
		node.master.setup(cfg);
		node.onRehash(null,null);
		return 0;
	}

	internal int onFork_Before(extring*arg, extring*output) {
		node.master.node.onFork_Before(arg, output);
		return 0;
	}

	internal int onFork_After_Parent(extring*arg, extring*output) {
		node.master.onFork_After_Parent(arg, output);
		return 0;
	}
	internal int onFork_After_Child(extring*arg, extring*output) {
		print("child should do something here\n");
		node.onFork_After_Child(arg, output);
		return 0;
	}
	internal int onRehash(extring*arg, extring*output) {
		OutputStream?lbsink = null;
		extring entry = extring.set_static_string("http/mitigateway/connectionoriented/outgoing/sink");
		PluginManager.acceptVisitor(&entry, (x) => {
			lbsink = (OutputStream)x.getInterface(null);
		});
		OutputStream?hsink = null;
		entry.rebuild_and_set_static_string("http/connectionoriented/incoming/sink");
		PluginManager.acceptVisitor(&entry, (x) => {
			hsink = (OutputStream)x.getInterface(null);
		});
		return node.onRehash(hsink, lbsink);
	}
	internal int onQuit(extring*arg, extring*output) {
		return node.master.onQuit(arg, output);
	}
}
/* @} */
