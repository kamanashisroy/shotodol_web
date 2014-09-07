using aroop;
using shotodol;
using shotodol.netio;
using shotodol.http_gateway;

/***
 * \addtogroup http_gateway
 * @{
 */
public class shotodol.http_gateway.HTTPGatewayModule : DynamicModule {
	TCPPacketSorterServer?server;	
	HTTPGatewayModule() {
		extring nm = extring.set_string(core.sourceModuleName());
		extring ver = extring.set_static_string("0.0.0");
		base(&nm,&ver);
		server = null;
	}

	~HTTPGatewayModule() {
	}

	public override int init() {
		extring entry = extring.set_static_string("onQuit");
		Plugin.register(&entry, new HookExtension(onQuitHook, this));
		entry.rebuild_and_set_static_string("onReady");
		Plugin.register(&entry, new HookExtension(onReadyHook, this));
		return 0;
	}
	void createServer() {
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
		extring stack = extring.set_static_string("http");
		server = new TCPPacketSorterServer(&stack, &laddr);
	}
	int onReadyHook(extring*msg, extring*output) {
		print("On ready\n");
		createServer();
		server.registerAllHooks(this);
		server.rehashHook(null,null);
		extring entry = extring.set_static_string("command");
		Plugin.register(&entry, new M100Extension(new HTTPGatewayCommand(server), this));
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
