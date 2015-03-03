
function onLoad() 
	return "page/index page/example"
end

function exten_page_index(x) 
	local msg =  "<html>Congratulations!, it works.<ul><li><a href=\"/console\">Console</a></li><li><a href=\"/example\">more example</a></li></ul></html>\n"
	OutputStream.write(msg)
	return(msg)
end

function exten_page_example(x) 
	local msg =  "Congratulations!, it works too.\n"
	OutputStream.write(msg)
	return(msg)
end
