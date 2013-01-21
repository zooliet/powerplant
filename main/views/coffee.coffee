# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


jQuery ->
	spectrogram = ->
		numRows = 45.0
		numCols = 45
		tooltipStrings = new Array()
		data = new google.visualization.DataTable()
		i = 0
		while i < numCols
			data.addColumn "number", "col" + i
			i++
		data.addRows numRows
		d = 360 / numRows
		idx = 0
		i = 0
		while i < numRows
			j = 0
			while j < numCols
				value = (Math.cos(i * d * Math.PI / 180.0))
				data.setValue i, j, value / 4.0
				tooltipStrings[idx] = "x:" + i + ", y:" + j + " = " + value
				idx++
				j++
			i++
	
		surfacePlot = new greg.ross.visualisation.SurfacePlot(document.getElementById("spectrogram"))
		# Don't fill polygons in IE. It's too slow.
		fillPly = true
		# Define a colour gradient.
		colour1 =
			red: 0
			green: 0
			blue: 255
		colour2 =
			red: 0
			green: 255
			blue: 255
		colour3 =
			red: 0
			green: 255
			blue: 0
		colour4 =
			red: 255
			green: 255
			blue: 0
		colour5 =
			red: 255
			green: 0
			blue: 0
		colours = [colour1, colour2, colour3, colour4, colour5]
		# Axis labels.
		xAxisHeader = "X"
		yAxisHeader = "Y"
		zAxisHeader = "Z"
		options =
			xPos: 300
			yPos: 50
			width: 500
			height: 500
			colourGradient: colours
			fillPolygons: fillPly
			tooltips: tooltipStrings
			xTitle: xAxisHeader
			yTitle: yAxisHeader
			zTitle: zAxisHeader
		
		surfacePlot.draw data, options
	
	# google.load "visualization", "1"
	# google.setOnLoadCallback surface_setup

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
				# for k,v of result
				# 	$('div.box').append("<p>#{k} is #{v}</p>")
				# 	console.log(k + " is " + v)
					
########################################################################################										



########################################################################################					

	plot =
		current: 
			a = ( 0 for i in [1...1024])
		average: 
			a = ( 0 for i in [1...1024])

		picks: (bins, interval) ->
			ret = []
			accumulator = 0
			bins.forEach (value, index) ->
				if (index+1) % interval == 0
					accumulator = accumulator + value
					accumulator = accumulator / interval
					ret.push([index*190.73486328125, accumulator])   #fs / N = 195312.5 / 1024
					accumulator = 0
				else
					accumulator = accumulator + value
			ret
							
		start: (average=@average, current = @current, interval = 1) ->
			current_ret  = @.picks(current, interval)	
			average_ret  = @.picks(average, interval)			
						
			$.jqplot 'graph', [average_ret, current_ret],
				seriesColors: ["rgba(78, 135, 194, 0.7)", "rgb(211, 235, 59)"] # seriesColors: [ "#c5b47f"]
				# seriesColors: ["rgba(78, 135, 194, 0.7)"]
				
				title: "Ultra-Acoustic Spectrum"
				series: [{fill: true}, {}]
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
						min: 0			# min: current_ret[0][0]
						max: 95000  # max: current_ret[current_ret.length-1][0]
						# renderer: $.jqplot.CategoryAxisRenderer
						drawMajorGridlines: true
						showTicks: true
						numberTicks: 20
						# tickInterval: 8
						# labelRenderer: $.jqplot.CanvasAxisLabelRenderer
						# label: "Hz"
						# tickRenderer: $.jqplot.CanvasAxisTickRenderer
						tickOptions: 
							formatString: "%d"
							# showGridline: true
							# showMark: true
					yaxis:
						# renderer: $.jqplot.LogAxisRenderer
						forceTickAt0: true
						pad: 0
						rendererOptions:
							minorTicks: 1
						tickOptions:
							formatString: "%d dB"
							# formatString:'%.1f'
							showMark: false
						min: 0
						max: 100
						tickInterval: 10
						# autoscale: true 						
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
	

########################################################################################

	# plot.click_binding()
	gplot = plot.start()

########################################################################################

	hostip = $('div#hostip').data('hostip')
	ws = new WebSocket("ws://#{hostip}:8080/")

	ws.onmessage = (evt) ->
		result = $.parseJSON(evt.data)  #JSON.stringify(evt.data)
		# console.log(result)
		# for k,v of result
		# 	console.log(k + " is " + v)
		gplot.destroy()
		gplot = plot.start(result.average, result.current)
		gplot.replot()
								
	ws.onclose = ->
		# alert("Socket closed")

	ws.onopen = ->
		# alert("Connected...")
		# ws.send("Hello Server")

########################################################################################					

	$('div#controls ul.buttons li').live "click", ->
		url = $(@).data('ref')
		if url is '/start' or url is '/stop' or url is '/calibration'
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
					$('div#spectrogram').empty()
					spectrogram()
					
					# for k,v of result
					# 	console.log(k + " is " + v)
			
		$('div#controls ul.buttons li.active').removeClass('active')
		$(@).addClass('active')
	
