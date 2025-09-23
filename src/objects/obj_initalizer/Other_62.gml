var loadID = async_load[? "id"]

if (loadID == request) {
	var status = async_load[? "status"];
	
	if (status == 0) {
		connectedToInternet = 1;
	} else if (status < 0) { //error
		connectedToInternet = -1;
	}
}