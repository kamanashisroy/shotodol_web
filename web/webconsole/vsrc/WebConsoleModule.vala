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
			output.concat_string("<form action=\"/console/action\"");
			//output.concat(&nm);
			output.concat_string(" target=\"shotodolOutput\"/>");
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
			output.concat_string("<input type=\"submit\" name=\"command\" value=\"");
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
		extring target = extring.stack(64);
		extring param = extring.stack(512);
		bool nextIsCommand = false;
		Bundler bndlr = Bundler();
		bndlr.build_extring_reader(msg, BundlerAffixes.PREFIX);
#if HTTP_HEADER_DEBUG
		print("request length:%d\n", msg.length());
#endif
		try {
			while(true) {
				int key = bndlr.next();
				if(key == -1) break;
				if(key != httpRequest.REQUEST_QUERY_KEY && key != httpRequest.REQUEST_QUERY_VALUE)
					continue;
				if(bndlr.getContentType() != BundledContentType.STRING_CONTENT) continue;
				extring harg = extring();
				bndlr.getEXtring(&harg);
#if HTTP_HEADER_DEBUG
				print("arg:[%s][%d]\n", harg.to_string(), harg.length());
#endif
				if(key == httpRequest.REQUEST_QUERY_KEY && harg.equals_static_string("command")) {
					nextIsCommand = true;
					continue;
				}
				if(!nextIsCommand) {
					param.concat(&harg);
					param.concat_string(" ");
#if HTTP_HEADER_DEBUG
					print("Param : %s\n", param.to_string());
#endif
					continue;
				}
				target.concat(&harg);
#if HTTP_HEADER_DEBUG
				print("Target command : %s\n", target.to_string());
#endif
				nextIsCommand = false;
			}
		} catch(BundlerError err) {
#if HTTP_HEADER_DEBUG
			print("------------------ Error !\n");
#endif
		}
#if HTTP_HEADER_DEBUG
		print("Target command : %s\n", target.to_string());
#endif
		if(target.is_empty())
			return 0;
		// Prepare command string
		extring cmdstr = extring.stack(512);
		cmdstr.concat(&target);
		cmdstr.concat_string(" ");
		cmdstr.concat(&param);
		cmdstr.concat_string("\r\n");
		cmdstr.zero_terminate();
#if HTTP_HEADER_DEBUG
		print("executing %s\n", cmdstr.to_string());
#endif
		extring entry = extring.set_static_string("command/server");
		Plugin.swarm(&entry, &cmdstr, output);
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
