using aroop;
using shotodol;
using shotodol.netio;
using shotodol.http_gateway;

/** \addtogroup http_gateway
 *  @{
 */
internal class shotodol.http_gateway.HTTPGatewayCommand : M100Command {
	ConnectionOrientedPacketConveyorBelt?server;	
	unowned HTTPGatewayModule?mod;
	public HTTPGatewayCommand(HTTPGatewayModule?givenMod) {
		var prefix = extring.set_static_string("httpgateway");
		base(&prefix);
		server = null;
		mod = givenMod;
	}
	public override int act_on(extring*cmdstr, OutputStream pad, M100CommandSet cmds) {
		if(server == null) {
			extring dlg = extring.set_static_string("Setting up server\n");
			pad.write(&dlg);
			setup();
		}
		return 0;
	}
	void setup() {
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
		server = new ConnectionOrientedPacketConveyorBelt(&stack, &laddr);
		server.registerAllHooks(mod);
		entry.rebuild_and_set_static_string("onQuit/soft");
		Plugin.register(&entry, new HookExtension(onQuitHook, mod));
		server.rehashHook(null,null);
	}
	int onQuitHook(extring*msg, extring*output) {
		if(server != null)
			server.close();
		server = null;
		return 0;
	}
}
/* @} */
