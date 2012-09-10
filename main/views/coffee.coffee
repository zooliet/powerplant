# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
	$.jqplot._noToImageButton = true;
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
########################################################################################					


########################################################################################					

	plot =
		current: 
			a = ( i for i in [1...1024])
		# average: 
		# 	[].push(50) for i in [0...1024]
		# max: 
		# 	[].push(100) for i in [0...1024]		
		# min: 
		# 	[].push(0) for i in [0...102412]		

		picks: (bins, interval) ->
			ret = []
			accumulator = 0
			bins.forEach (value, index) ->
				if (index+1) % interval == 0
					accumulator = accumulator + value
					accumulator = accumulator / interval
					ret.push([index*8, accumulator])
					accumulator = 0
				else
					accumulator = accumulator + value
			ret
			
		
		diff: (previous=@previous, current=@current, interval=8) ->
			previous_ret = @.picks(previous, interval)			
			current_ret  = @.picks(current, interval)			
			diff_ret = []
			for i in [0...previous_ret.length]
				value = current_ret[i][1] - previous_ret[i][1]
				diff_ret.push([i, value])

			$.jqplot 'graph', [diff_ret],
				title: "Ultra-Acoustic Spectrum"
				# animate: true
				# animateReplot: true
				seriesDefaults:
					renderer:$.jqplot.BarRenderer
					# pointLabels: { show: true }
					rendererOptions: 
						barWidth: 2
						# barPadding: -15
						# barMargin: 0
						highlightMouseOver: true
						fillToZero: true
						shadow: false
				axes:
					# yaxis: { autoscale: true }
					xaxis:
						# renderer: $.jqplot.CategoryAxisRenderer
						drawMajorGridlines: true
						showTicks: true
						# labelRenderer: $.jqplot.CanvasAxisLabelRenderer
						# label: "HELLO"
						min: 0
						max: diff_ret[diff_ret.length-1][0]
						numberTicks: 8
						# tickRenderer: $.jqplot.CanvasAxisTickRenderer
						# tickOptions: 
						# 	showGridline: true
						# 	showMark: true
						# 	tickInteval: 4
				grid: 
					background: 'rgba(57,57,57,0.0)'
					drawBorder: true
					shadow: false
					# gridLineColor: '#66666'
					# gridLineWidth: 1
				highlighter:
					show: true
					sizeAdjust: 1
					# tooltipLocation: 'w'
					# tooltipAxes: 'y'
					# tooltipFormatString: '<b><i><span style="color:black;">%.1f</span></i></b>'
					useAxesFormatters: false
				cursor:
					show: true
				
		start: (current = @.current, interval = 2) ->
		# start: (current=@current, average=@average, max=@max, min=@min, interval=2) ->
			# previous_ret = @.picks(previous, interval)			
			# current_ret  = @.picks(current, interval)	
			current_ret = current		
			# average_ret  = @.picks(average, interval)			
			# max_ret  		 = @.picks(max, interval)			
			# min_ret  		 = @.picks(min, interval)			
						
			$.jqplot 'graph', [current_ret],
			# $.jqplot 'graph', [current_ret, average_ret, max_ret, min_ret],
			# 	seriesColors: ["rgba(78, 135, 194, 0.7)", "rgb(211, 235, 59)", "rgb(192,0,0)", "rgb(0,0,192)"] # seriesColors: [ "#c5b47f"]
				seriesColors: ["rgba(78, 135, 194, 0.7)"]
				
				title: "Ultra-Acoustic Spectrum"
				# series: [{fill: true}, {}]
				# fillBetween: {
				# 	series1: 2
				# 	series2: 3
				# 	color: "rgba(227, 167, 111, 0.7)"
				# 	baseSeries: 0,
				# 	fill: true
				# }
        
				seriesDefaults: 
					showMarker: false
					# pointLabels:{ 
					# 	show:true
					# 	# location:'s'
					# 	ypadding: 3 
					# 	location: 'se'
					# 	edgeTolerance: 10
					# }
					rendererOptions: 
						smooth: true
						animation:
							show: true
				axesDefaults:
					rendererOptions:
						baselineWidth: 1.5
						baselineColor: '#444444'
						drawBaseline: false
				axes:
					xaxis:
						# min: 1
						# max: previous_ret.length
						min: current_ret[0][0]
						max: current_ret[current_ret.length-1][0]
						# numberTicks: 12
						# tickInterval: 8
						tickOptions: 
							formatString: "%d Hz"
					yaxis:
						renderer: $.jqplot.LogAxisRenderer
						forceTickAt0: true
						pad: 0
						rendererOptions:
							minorTicks: 1
						tickOptions:
							formatString: "%'d"
							# formatString:'%.1f'
							showMark: false
						# min: 0
						# max: 100
						# tickInterval: 10
				grid: 
					background: 'rgba(57,57,57,0.0)'
					drawBorder: true
					shadow: false
					# gridLineColor: '#66666'
					# gridLineWidth: 1
				highlighter:
					show: true
					sizeAdjust: 1
					# tooltipLocation: 'w'
					# tooltipAxes: 'y'
					# tooltipFormatString: '<b><i><span style="color:black;">%.1f</span></i></b>'
					useAxesFormatters: false
				cursor:
					show: true
		# click_binding: ->
		# 	$('div#graph').live 'jqplotDataClick', (ev, seriesIndex, pointIndex, data) ->
		# 		# alert("#{data[0]}")
		# 		plot.start(plot.current, plot.previous, 4).replot()


########################################################################################

	# plot.click_binding()
	plot.start()

########################################################################################

	hostip = $('div#hostip').data('hostip')
	ws = new WebSocket("ws://#{hostip}:8080/")
	
	ws.onmessage = (evt) ->
		result = $.parseJSON(evt.data)  #JSON.stringify(evt.data)
		# console.log(result)
		# for k,v of result
		# 	console.log(k + " is " + v)
		
		# result = evt.data
		# plot.start(result.current, result.average, result.max, result.min, 4).replot()
		# plot.start(result.current, 4)
		# plot.start((0 for i in [1...1024]));
		plot.start(result.current).replot()
		# console.log(result.current)
		
	ws.onclose = ->
		# alert("Socket closed")

	ws.onopen = ->
		# alert("Connected...")
		# ws.send("Hello Server")

########################################################################################					

	$('div#controls ul.buttons li').live "click", ->
		url = $(@).data('ref')
		if url is '/start' or url is '/stop'
			url = "#{url}.js"
			type = 'script'
			$.ajax
				type: 'GET'
				dataType: type
				url: url			
		else
			url = "#{url}.json"
			type = 'json'
			$.ajax
				type: 'GET'
				dataType: type
				url: url
				success: (result) ->
					for k,v of result
						console.log(k + " is " + v)
					if result.type == "normal"
						plot.start(result.current, result.average, result.max, result.min, result.interval).replot()
					else
						plot.diff(result.previous, result.current, result.interval).replot()
	
	$('div#siggen table tr').live "click", ->
		url = $(@).data('ref')
		type = 'script'
		$.ajax
			type: 'GET'
			dataType: type
			url: "#{url}.js"	
		
		$('div#siggen table tr.active').removeClass('active')
		$(@).addClass('active')
	


