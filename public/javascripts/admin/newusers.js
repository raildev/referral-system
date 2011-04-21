$(document).ready(function() {
	$("#createusers").validate({
		rules: {
			user_name: {
				required: function(element) { return $('#phone_number').val().length == 0 },
			},
			password: {
				required: function(element) { return $('#phone_number').val().length == 0 },
			},
			email: {
				required: function(element) { return $('#phone_number').val().length == 0 },
				email: true,
			},
			phone_number: {
				required: function(element) { return $('#user_name').val().length == 0 || $('#password').val().length == 0 || $('#email').val().length == 0 },
				number: true,
			},
			place_code: {
				number: true
			}
		},
		messages: {
			user_name: {
				required: "Required unless you provide a phone number"		
			},
			email: {
				required: "Required unless you provide a phone number"		
			},
			password: {
				required: "Required unless you provide a phone number"		
			},
		   	phone_number: {
				required: "Required unless you provide a username, email and password"		
			}		
		},
		errorPlacement: function(error, element) { 
            error.appendTo(element.next()); 
        },
	});
		
	$("#addMoreUser").click(function(){	
		addRow();
    });

	$('#createusers .input').blur(function(){
		$('#phone_number').valid();	
	});
});

function addRow() {
	if ($('#createusers').valid()) {	
		var name = $("#user_name").val();
		var email = $("#email").val();
		var password = $("#password").val();
		var phone = $("#phone_number").val();
		var place_code = $("#place_code").val();

		var icon = '<div style="float:right;"><img src="/images/trash.png" alt="Remove" title="Remove" class="clickable removeRow"/></div> ';

		var tr = "<tr>" +
		         "<td><input type='hidden' name='admin[user_name][]' value='" + name + "' /> " + name +  " </td>" +
		         "<td><input type='hidden' name='admin[email][]' value='" + email + "' /> " + email + " </td>" +
		         "<td><input type='hidden' name='admin[password][]' value='" + password + "' /> " + showPwd(password) + " </td>" +
		         "<td><input type='hidden' name='admin[phone_number][]' value='"+ phone + "' />" + phone + "</td>" +
		         "<td><input type='hidden' name='admin[place_code][]' value='" + place_code  + "' />" + place_code + "</td>" +
		         "<td>" + icon + "</td>" +			
		         "</tr>" ;

		var tr_new = $(tr);
		tr_new.insertBefore($("#inputRow"));     
		addIconClick();
	}
}

function addIconClick() {
	var clickable = $(".removeRow");
	var last = clickable.length;
	var clickable_new = clickable.get(last - 1);

	$(clickable_new).click(function(){
	   var tr = this.parentNode.parentNode.parentNode;
	   tr.parentNode.removeChild(tr);
	});
}

function showPwd(pwd) {
	var str = "";
	for (var i = 0; i < pwd.length; i++) str += "*" ;
	return str;
}