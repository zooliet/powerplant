$(document).ready(function() {
  $("#clickme").click(function(e){
		e.preventDefault();
		$.getScript("/coffee.js");		
	});
});