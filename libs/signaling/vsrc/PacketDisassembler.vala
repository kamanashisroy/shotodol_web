using aroop;
using shotodol;

/***
 * \addtogroup signaling
 * @{
 */
public abstract class shotodol.signaling.PacketDisassembler : Replicable {
	public abstract int parse(extring*outUrl, Bag?header, extring*pkt);
}

/** @} */
