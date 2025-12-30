if (!testingInternet) return;

var loadID = async_load[? "id"];

if (loadID == request) {
	var status = async_load[? "status"];
	var httpStatus = async_load[? "http_status"];
	
	if (status) {
		show_message(string_replace_all(string(@"Request made to {0}
		request: {1}
		loadID: {2}
		httpStatus: {3}
		status: {4}
		", requestURL, request, loadID, httpStatus, status), "	", "- "));
	}
}