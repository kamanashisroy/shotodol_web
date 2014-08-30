using aroop;
using shotodol;
using shotodol.http_gateway;

/***
 * \addtogroup http_gateway
 * @{
 */
public class shotodol.http_gateway.HTTPGatewayModule : DynamicModule {
	HTTPPacketSorterServer?server;	
	HTTPGatewayModule() {
		extring nm = extring.set_string(core.sourceModuleName());
		extring ver = extring.set_static_string("0.0.0");
		base(&nm,&ver);
		server = null;
	}

	~HTTPGatewayModule() {
	}

	public override int init() {
		CompositeOutputStream sink = new CompositeOutputStream();
		server = new HTTPPacketSorterServer(sink);
		extring entry = extring.set_static_string("MainSpindle");
		Plugin.register(&entry, new AnyInterfaceExtension(server, this));
		entry.rebuild_and_set_static_string("rehash");
		Plugin.register(&entry, new HookExtension(server.rehashHook, this));
		entry.rebuild_and_set_static_string("http/response/sink");
		Plugin.register(&entry, new AnyInterfaceExtension(sink, this));
		entry.rebuild_and_set_static_string("command");
		Plugin.register(&entry, new M100Extension(new HTTPGatewayCommand(server), this));
		entry.rebuild_and_set_static_string("onQuit");
		Plugin.register(&entry, new HookExtension(onQuitHook, this));
		return 0;
	}
	int onQuitHook(extring*msg, extring*output) {
		if(server != null)
			server.close();
		return 0;
	}
	public override int deinit() {
		server = null;
		base.deinit();
		return 0;
	}
	
	[CCode (cname="get_module_instance")]
	public static Module get_module_instance() {
		return new HTTPGatewayModule();
	}
}

/** @} */
