using aroop;
using shotodol;
using shotodol.netio;
using shotodol.http_mitigateway;

/***
 * \addtogroup http_mitigateway
 * @{
 */
public class shotodol.http_mitigateway.HTTPMitigatewayModule : DynamicModule {
	HTTPMitigatewayModule() {
		extring nm = extring.set_string(core.sourceModuleName());
		extring ver = extring.set_static_string("0.0.0");
		base(&nm,&ver);
	}

	~HTTPMitigatewayModule() {
	}

	public override int init() {
		HTTPLoadBalancerCommand cmd = new HTTPLoadBalancerCommand(this);
		extring entry = extring.set_static_string("command");
		PluginManager.register(&entry, new M100Extension(cmd, this));
		entry.rebuild_and_set_static_string("onFork/before");
		PluginManager.register(&entry, new HookExtension(cmd.onFork_Before, this));
		entry.rebuild_and_set_static_string("onFork/after/parent");
		PluginManager.register(&entry, new HookExtension(cmd.onFork_After_Parent, this));
		entry.rebuild_and_set_static_string("onFork/after/child");
		PluginManager.register(&entry, new HookExtension(cmd.onFork_After_Child, this));
		entry.rebuild_and_set_static_string("rehash");
		PluginManager.register(&entry, new HookExtension(cmd.onRehash, this));
		entry.rebuild_and_set_static_string("onQuit/soft");
		PluginManager.register(&entry, new HookExtension(cmd.onQuit, this));
		return 0;
	}

	public override int deinit() {
		base.deinit();
		return 0;
	}
	
	[CCode (cname="get_module_instance")]
	public static Module get_module_instance() {
		return new HTTPMitigatewayModule();
	}
}

/** @} */
