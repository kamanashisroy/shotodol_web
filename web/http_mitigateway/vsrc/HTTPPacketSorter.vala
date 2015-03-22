using aroop;
using shotodol;
using shotodol_platform;

/***
 * \addtogroup http_mitigateway
 * @{
 */
public class shotodol.http_mitigateway.HTTPPacketSorter : OutputStream32x {
	public HTTPPacketSorter() {
		base();
	}

	~HTTPPacketSorter() {
	}

	public override int write(extring*buf) throws IOStreamError.OutputStreamError {		
		extring x = extring.copy_shallow(buf);
		x.makeConstant();		
		print("----------------------------------------------------------------\n");
		int i = 0;
		for(i = 2; i < x.length(); i++) 
		{ 
		    	if(x.char_at(i) == '&' && x.char_at(i+1) == 'f' && x.char_at(i+2) == 'o' && x.char_at(i+3) == 'r' 
			&& x.char_at(i+4) == 'k' && x.char_at(i+5) == 'I' && x.char_at(i+6) == 'n' && x.char_at(i+7) == 'd' 
			&& x.char_at(i+8) == 'e' && x.char_at(i+9) == 'x' && x.char_at(i+10) == '=') 
			{ 
				extring line = extring.stack(2);
				line.concat_char(x.char_at(i+11));
				line.concat_char(x.char_at(i+12));
				int id = line.to_int();				
				print("---- %d\n",id);
				if(id >= count)
					break;		
				return sink[id].write(buf);
		    	}
		}
		print("----------------------------------------------------------------\n");
		return (sink[0] != null)?sink[0].write(buf):0;
		//return buf.length();
		/** sanity check */
/*
		if(count == 0 || buf.length() <= wpos+2)
			return buf.length(); // This data is lost and we do not know the way to route them.
		aroop_uword16 x = 0;
		x = buf.char_at(wpos);
		x = x << 8;
		x |= buf.char_at(wpos + 1);
		if(x == 0) {
			x = resolveZero(buf);
		} else {
			x = x%count;
		}
		return sink[x].write(buf);
*/
	}
}

/** @} */
