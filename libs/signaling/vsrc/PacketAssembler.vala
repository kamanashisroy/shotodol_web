using aroop;
using shotodol;

/***
 * \addtogroup signaling
 * @{
 */
public abstract class shotodol.signaling.PacketAssembler : Replicable {
	public abstract int send(Bag state, Bundler*pkt);
}

/** @} */
