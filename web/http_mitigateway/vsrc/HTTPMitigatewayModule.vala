using aroop;
using shotodol;
using shotodol.netio;
using shotodol.http_lbgateway;

/***
 * \addtogroup http_lbgateway
 * @{
 */
public class shotodol.http_lbgateway.HTTPMitigatewayModule : DynamicModule {
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
		Plugin.register(&entry, new M100Extension(cmd, this));
		entry.rebuild_and_set_static_string("onFork/before");
		Plugin.register(&entry, new HookExtension(cmd.onFork_Before, this));
		entry.rebuild_and_set_static_string("onFork/after/parent");
		Plugin.register(&entry, new HookExtension(cmd.onFork_After_Parent, this));
		entry.rebuild_and_set_static_string("onFork/after/child");
		Plugin.register(&entry, new HookExtension(cmd.onFork_After_Child, this));
		entry.rebuild_and_set_static_string("rehash");
		Plugin.register(&entry, new HookExtension(cmd.onRehash, this));
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
