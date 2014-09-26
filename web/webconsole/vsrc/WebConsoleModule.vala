using aroop;
using shotodol;
using shotodol_platform;

/** \addtogroup http
 *  @{
 */
public class shotodol.web.WebConsoleModule : DynamicModule {

	public WebConsoleModule() {
		extring nm = extring.set_string(core.sourceModuleName());
		extring ver = extring.set_static_string("0.0.0");
		base(&nm,&ver);
	}

	public override int init() {
		extring entry = extring.set_static_string("page/console");
		Plugin.register(&entry, new HookExtension(onCommandPage, this));
		entry.rebuild_and_set_static_string("page/console/action");
		Plugin.register(&entry, new HookExtension(onCommandActionPage, this));
		return 0;
	}

	int onCommandPage(extring*msg, extring*output) {
		output.rebuild_in_heap(4096);
		output.concat_string("<html>");
		output.concat_string("<h1>Commands</h1>");
		output.concat_string("<ul>");
		extring entry = extring.set_static_string("command");
		Plugin.acceptVisitor(&entry, (x) => {
			M100Command?cmd = (M100Command)x.getInterface(null);
			if(cmd == null) {
				return;
			}
			output.concat_string("<li>");
			extring nm = extring();
			cmd.getPrefixAs(&nm);
			//output.concat(&nm);
			output.concat_string("<form action=\"/console/action/?command=");
			output.concat(&nm);
			output.concat_string("&\" target=\"shotodolOutput\"/>");
			Iterator<M100CommandOption> it = Iterator<M100CommandOption>.EMPTY();
			cmd.getOptionsIterator(&it);
			while(it.next()) {
			//cmd.acceptOptionsVisitor((opt) => {
				//opt.desc(pad);
				M100CommandOption? opt = it.get();
				extring optnm = extring();
				opt.getPrefixAs(&optnm);
				output.concat(&optnm);
				switch(opt.getType()) {
					case M100Command.OptionType.TXT:
					case M100Command.OptionType.INT:
						output.concat_string("<input type=\"text\" ");
					break;
					case M100Command.OptionType.NONE:
						output.concat_string("<input type=\"checkbox\" ");
					break;
				}
				output.concat_string("name=\"");
				output.concat(&optnm);
				output.concat_string("\"></input>");
			//});
			}
			output.concat_string("<input type=\"submit\" value=\"");
			output.concat(&nm);
			output.concat_string("\"></input>");
			//cmd.desc(M100Command.CommandDescType.COMMAND_DESC_TITLE, pad);
			output.concat_string("</form>");
			output.concat_string("</li>");
		});
		//output.concat_string("<frame name=\"shotodolOutput\"></frame>");
		output.concat_string("</ul>");
		output.concat_string("</html>");
		return 0;
	}

	int onCommandActionPage(extring*msg, extring*output) {
		extring cmd = extring();
		// TODO parse the parameters and execute command
		extring entry = extring.set_static_string("command/server");
		Plugin.swarm(&entry, &cmd, output);
		return 0;
	}

	public override int deinit() {
		base.deinit();
		return 0;
	}
	[CCode (cname="get_module_instance")]
	public static Module get_module_instance() {
		return new WebConsoleModule();
	}
}

/* @} */
