using aroop;
using shotodol;
using syncproto;

/***
 * \addtogroup signaling
 * @{
 */
public abstract class shotodol.signaling.PacketDisassembler : Replicable {
	public abstract int parse(Bag state, extring*pkt);
}

/** @} */
