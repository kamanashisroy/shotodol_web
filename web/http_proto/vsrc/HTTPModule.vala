using aroop;
using shotodol;
using shotodol.web;

/**
 * \ingroup web
 * \defgroup http HTTP library
 * [Cohesion : Functional]
 */

/** \addtogroup http
 *  @{
 */
public class shotodol.web.HTTPModule : shotodol.DynamicModule {
	public HTTPModule() {
		extring nm = extring.set_string(core.sourceModuleName());
		extring ver = extring.set_static_string("0.0.0");
		base(&nm,&ver);
	}
	public override int init() {
		HTTPRequestSink sink = new HTTPRequestSink();
		extring entry = extring.set_static_string("http/connectionoriented/incoming/sink");
		sink.setName(&entry);
		PluginManager.register(&entry, new AnyInterfaceExtension(sink, this));
		entry.rebuild_and_set_static_string("rehash");
		PluginManager.register(&entry, new HookExtension(sink.rehashHook, this));
		//entry.rebuild_and_set_static_string("onReadyAlter");
		//PluginManager.register(&entry, new HookExtension(sink.rehashHook, this));
		entry.rebuild_and_set_static_string("status");
		PluginManager.register(&entry, new HookExtension((sink.statusHook), this));
		return 0;
	}
	public override int deinit() {
		base.deinit();
		return 0;
	}
	[CCode (cname="get_module_instance")]
	public static Module get_module_instance() {
		return new HTTPModule();
	}
}
/** @}*/
