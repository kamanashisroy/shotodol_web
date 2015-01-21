using aroop;
using shotodol;
using shotodol.http.signaling;

/***
 * \addtogroup http.signaling
 * @{
 */
public class shotodol.http.signaling.HTTPSignalingModule : DynamicModule {
	HTTPSignalingModule() {
		extring nm = extring.set_string(core.sourceModuleName());
		extring ver = extring.set_static_string("0.0.0");
		base(&nm,&ver);
	}

	~HTTPSignalingModule() {
	}

	public override int init() {
		extring entry = extring.set_static_string("http/signaling/disassembler");
		Plugin.register(&entry, new AnyInterfaceExtension(new HTTPPacketDisassembler(), this));
		return 0;
	}
	public override int deinit() {
		base.deinit();
		return 0;
	}
	
	[CCode (cname="get_module_instance")]
	public static Module get_module_instance() {
		return new HTTPSignalingModule();
	}
}

/** @} */
