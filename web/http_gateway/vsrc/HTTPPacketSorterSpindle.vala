using aroop;
using shotodol;
using shotodol.http_gateway;

/***
 * \addtogroup http_gateway
 * @{
 */
public abstract class shotodol.http_gateway.HTTPPacketSorterSpindle : Spindle {
	protected bool poll;
	protected int interval;
	protected shotodol_platform_net.NetStreamPollPlatformImpl pl;
	public HTTPPacketSorterSpindle() {
		base();
		interval = 10;
		pl = shotodol_platform_net.NetStreamPollPlatformImpl();
	}

	~HTTPPacketSorterSpindle() {
	}
	public override int step() {
		if(!poll) {
			return 0;
		}
		shotodol_platform.ProcessControl.millisleep(interval);
		pl.check_events();
		do {
			shotodol_platform_net.NetStreamPlatformImpl*x = pl.next();
			if(x == null) {
				break;
			}
			if(onEvent(x)!=0) {
				break;
			}
		} while(true);
		return 0;
	}
	public override int cancel() {
		return 0;
	}
	internal abstract int onEvent(shotodol_platform_net.NetStreamPlatformImpl*x);
}

/** @} */
