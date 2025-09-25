if (!testingInternet) return;

var loadID = async_load[? "id"]

if (loadID == request) {
	var status = async_load[? "status"];
	var httpStatus = async_load[? "http_status"];
	
	if (status) {
		show_message(
		"request: " + string(request) + 
		"loadID: " + string(loadID) + 
		"httpStatus: " + string(httpStatus) + 
		"\nstatus: " + string(status));
	}
}