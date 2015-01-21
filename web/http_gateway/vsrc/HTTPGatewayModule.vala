using aroop;
using shotodol;
using shotodol.netio;
using shotodol.http_gateway;

/***
 * \addtogroup http_gateway
 * @{
 */
public class shotodol.http_gateway.HTTPGatewayModule : DynamicModule {
	HTTPGatewayModule() {
		extring nm = extring.set_string(core.sourceModuleName());
		extring ver = extring.set_static_string("0.0.0");
		base(&nm,&ver);
	}

	~HTTPGatewayModule() {
	}

	public override int init() {
		extring entry = extring.set_static_string("command");
		Plugin.register(&entry, new M100Extension(new HTTPGatewayCommand(this), this));
		//entry.rebuild_and_set_static_string("onReady");
		//Plugin.register(&entry, new HookExtension(onReadyHook, this));
		return 0;
	}

	public override int deinit() {
		base.deinit();
		return 0;
	}
	
	[CCode (cname="get_module_instance")]
	public static Module get_module_instance() {
		return new HTTPGatewayModule();
	}
}

/** @} */
