jQuery ->
	$("a#coffee_click").live "click", (e) ->
		e.preventDefault()
		$.ajax
			type: 'GET',
			dataType: 'script',
			url: '/coffee_test.js'

	$("a#json_click").live "click", (e) ->
		e.preventDefault()
		$.ajax
			type: 'GET',
			dataType: 'json',
			url: '/json_test.json'
			success: (result) ->
				for k,v of result
					$('div.box').append("<p>#{k} is #{v}</p>")
					# console.log(k + " is " + v)
