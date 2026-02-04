if (!testingInternet) return;

var loadID = async_load[? "id"];

if (loadID == httpRequest) {
	var status = async_load[? "status"];
	var bytesReturned = (async_load[? "size"] ?? "unknown amount of");
	var httpStatus = async_load[? "http_status"];
	var requestTime = (current_time - httpReqStartTime);
	testingInternet = false;
	canInput = true;
	
	if (status) {
		printf("destinationURL={:1}, time={:2} ms, response={:3}", httpReqURL, requestTime, httpStatus);
	} else {
		printf("failed to resolve hostname: {:1}", httpReqURL);
	}
}