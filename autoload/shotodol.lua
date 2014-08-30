
function rehash() 
	return "page/index page/example"
end

function exten_page_index(x) 
	local msg =  "<html>Congratulations!, it works.<a href=\"/example\">more example</a></html>\n"
	OutputStream.write(msg)
	return(msg)
end

function exten_page_example(x) 
	local msg =  "Congratulations!, it works too.\n"
	OutputStream.write(msg)
	return(msg)
end
