using aroop;
using shotodol;
using shotodol.web;

/***
 * \addtogroup web
 * @{
 */
public class shotodol.web.HTTPPacketSorterModule : DynamicModule {
	
	HTTPPacketSorterModule() {
		extring nm = extring.set_string(core.sourceModuleName());
		extring ver = extring.set_static_string("0.0.0");
		base(&nm,&ver);
	}

	~HTTPPacketSorterModule() {
	}

	public override int init() {
		HTTPCompositeResponseSink sink = new HTTPCompositeResponseSink();
		HTTPPacketSorterServer server = new HTTPPacketSorterServer(sink);
		extring entry = extring.set_static_string("MainSpindle");
		Plugin.register(&entry, new AnyInterfaceExtension(server, this));
		entry.rebuild_and_set_static_string("rehash");
		Plugin.register(&entry, new HookExtension(server.rehashHook, this));
		entry.rebuild_and_set_static_string("http/response/sink");
		Plugin.register(&entry, new AnyInterfaceExtension(sink, this));
		//entry.rebuild_and_set_static_string("command");
		//Plugin.register(&entry, new M100Command(new HTTPServerCloseCommand(server), this));
		return 0;
	}
	public override int deinit() {
		base.deinit();
		return 0;
	}
	
	[CCode (cname="get_module_instance")]
	public static Module get_module_instance() {
		return new HTTPPacketSorterModule();
	}
}

/** @} */
