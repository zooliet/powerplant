# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


########################################################################################					

jQuery ->	
	spectral_data = []

	spectrogram = (result, angle) -> 
		numRows = 500
		numCols = result.length
		# alert(numCols)
		tooltipStrings = new Array()
		data = new google.visualization.DataTable()
		i = 0
		while i < numCols
			data.addColumn "number", "col" + i
			i++
		data.addRows numRows
		idx = 0
		i = 0
		while i < numRows
			j = 0
			while j < numCols
				value = result[j][i]
				data.setValue i, j, value / 100.0
				tooltipStrings[idx] = value + " at " + (Math.round(i * 190.73486328125)) + " Hz" 
				idx++
				j++
			i++
		
		surfacePlot = new greg.ross.visualisation.SurfacePlot(document.getElementById("spectrogram"))
		# Don't fill polygons in IE. It's too slow.
		fillPly = true
		# Define a colour gradient.
		colour1 = { red: 0,   green: 0,   blue: 255 }
		colour2 = { red: 0,   green: 255, blue: 255 }
		colour3 = { red: 0,   green: 255, blue: 0   }
		colour4 = { red: 255, green: 255, blue: 0   }
		colour5 = { red: 255, green: 0,   blue: 0   }
		colours = [colour1, colour2, colour3, colour4, colour5]
		
		# Axis labels.
		xAxisHeader = "Freq"
		yAxisHeader = "Time"
		zAxisHeader = "dBm"
		options =
			xPos: 0
			yPos: 0
			width: 800
			height: 600
			colourGradient: colours
			fillPolygons: fillPly
			tooltips: tooltipStrings
			xTitle: xAxisHeader
			yTitle: yAxisHeader
			zTitle: zAxisHeader
			angle: angle
		
		surfacePlot.draw(data, options)
	
	# google.load "visualization", "1"
	# google.setOnLoadCallback surface_setup
	
########################################################################################	
	
	slider = $("#slider").slider
		value: 48  #255
		min: 0  #1
		max: 95 #500
		step: 1
		slide: (event, ui ) ->
			# value = Math.round(parseInt(ui.value) * 190.73486328125)
			# value = ui.value * 1000
			value = ui.value
			$("#frequency").html("#{value} KHz")
	
	# value = Math.round(255 * 190.73486328125)	
	value = 48
	$("#frequency").html("#{value} KHz")


########################################################################################										

	plot =
		current: 
			a = ( -30 for i in [1...1024])
		average: 
			a = ( -30 for i in [1...1024])
		min: -30
		max: 70
		f_start: 0
		f_stop: 95000

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
							
		start: (average=@average, current=@current, start=@f_start, stop=@f_stop, min=@min, max=@max, interval=1) ->
			current_ret  = @.picks(current, interval)	
			average_ret  = @.picks(average, interval)			
						
			$.jqplot 'graph', [average_ret, current_ret],
				seriesColors: ["rgba(78, 135, 194, 0.7)", "rgb(211, 0, 0)"] # rgb(211, 235, 59) seriesColors: [ "#c5b47f"]
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
						min: start			
						max: stop  
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
							formatString: "%d dBm"
							# formatString:'%.1f'
							showMark: false
						min: min
						max: max
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
					zoom:	true
					showTooltip: false
					     
	
########################################################################################

	# plot.click_binding()	
	gplot = plot.start()

########################################################################################
	
	w = $('canvas:last').css('width')
	c = parseInt(w)/2
	p = $('canvas:last').position()
	
	$("div#slider").css('width': w);
	$("div#slider").css('left': "#{p.left}px");
	$("p#frequency").css('left': "#{p.left+c-10}px");

########################################################################################

	hostip = $('div#hostip').data('hostip')
	ws = new WebSocket("ws://#{hostip}:8080/")

	ws.onmessage = (evt) ->
		result = $.parseJSON(evt.data)  #JSON.stringify(evt.data)
		# console.log(result)
		# for k,v of result
		# 	console.log(k + " is " + v)
		gplot.destroy()
		# start =
		# stop  =
		# min   =
		# max   = 
		# gplot = plot.start(result.average, result.current, start, stop, min, max)
		gplot = plot.start(result.average, result.current)
		gplot.replot()
			
		if window.audio.flag
			freq_in_khz = $("#slider").slider( "value" )
			freq_index = Math.round((freq_in_khz * 1000) / 190.73486328125 )
			mags = []
			mags.push(Math.round(result.current[freq_index + i])) for i in [-1..1]
			console.log(mags.join(", "))
			window.audio.start(mags)		
								
	ws.onclose = ->
		# alert("Socket closed")

	ws.onopen = ->
		# alert("Connected...")
		# ws.send("Hello Server")

########################################################################################					

	$('div#controls ul.buttons li').live "click", ->
		$('#spectrogram').hide()
		$('#angle').hide()
		url = $(@).data('ref')
		if url is '/start' or url is '/stop' or url is '/calibration'
			url = "#{url}.js"
			type = 'script'
			$.ajax
				type: 'GET'
				dataType: type
				url: url			
			$('div#controls ul.buttons li.active').removeClass('active')
			$(@).addClass('active')
			
		else
			url = "#{url}.json"
			type = 'json'
			$.ajax
				type: 'GET'
				dataType: type
				url: url
				success: (result) ->
					data = []
					for k,v of result
						console.log(k + " is " + v)
						data.push(v)
					$('div#spectrogram').empty()
					$('#spectrogram').show()
					$('#angle').show()
					# data = []
					# for j in [0...60]
					# 	temp = []
					# 	for i in [0...500]
					# 		temp.push(Math.floor(j))
					# 		# temp.push(Math.floor(Math.random() * 60) + 1)
					# 	data.push(temp)
					spectrogram(data, 'normal')
					spectral_data = data
						
			$('div#controls ul.buttons li.active').removeClass('active')
			$(@).addClass('active')

########################################################################################					
	$('input[name=sound]:radio').change ->
		# alert("#{@value}")
		if @value is "on"
			window.audio.flag = true
		else
			window.audio.flag = false
			window.audio.stop()

	$('input[name=vspan]:radio').change ->
		# alert("#{@value}")
		if @value is "full"
			plot.min = -30
			plot.max = 70
		else
			plot.min = null
			plot.max = null

	$('a#reset_range').click (e) ->
		e.preventDefault()
		# gplot.resetZoom()
		$("input#range_start").val("0")
		$("input#range_stop").val("95")
		plot.f_start = 0
		plot.f_stop  = 95000
		$("#slider").slider
			value: 48
			min: 0
			max: 95
		$("#frequency").html("48 KHz")		

	$('a#apply_range').click (e) ->
		e.preventDefault()
		f_start = parseInt($("input#range_start").val())
		f_stop  = parseInt($("input#range_stop").val())
		plot.f_start = f_start * 1000
		plot.f_stop  = f_stop * 1000
		$("#slider").slider
			value: Math.round((f_start + f_stop)/2)
			min: f_start
			max: f_stop
		$("#frequency").html("#{Math.round((f_start + f_stop)/2)} KHz")		

												
########################################################################################	
	$("div#angle a").live "click", (e) ->
		$('div#spectrogram').empty()
		$('#spectrogram').show()
		e.preventDefault()
		if($(@).attr("id") is 'top')
			spectrogram(spectral_data, 'top')
		else
			spectrogram(spectral_data, 'normal')
	
########################################################################################	

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

class Audio
	constructor: ->
		# Number of samples to generate on each call to generateAudio.
		# Legal values are 256, 512, 1024, 2048, 4096, 8192, 16384.				
		BUFFER_SIZE = 1024
		# Number of output channels. We want stereo, hence 2 (though 1 also works??).
		NUM_OUTPUTS = 2	
		# We only want to *generate* audio, so our node has no inputs.
		# const NUM_INPUTS = 0; Results in horrible noise in Safari 6
		NUM_INPUTS = 1   # Works properly in Safari 6 
		# Create the audio context
		@context = new webkitAudioContext()
		# Create a source node
		@node = @context.createJavaScriptNode(BUFFER_SIZE, NUM_INPUTS, NUM_OUTPUTS)
		# Specify the audio generation function
		console.log(@node)

	start: (mags)->
		# Set up the per-sample phase increment based on the desired 
		# sine tone frequency and the sample rate of the audio context.
		# freqs = [523.25, 587.33, 659.26, 698.46, 784.00, 888.00, 987.6, 1046.5]
		# phase = [0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,   0.0]
		# inc   = []


		# freqs = [523.25, 587.33, 659.26, 698.46, 784.00, 888.00, 987.6, 1046.5, 1046.5, 1046.5, 1046.5]
		freqs = [784.00, 888.00, 987.6]

		phase = [0.0, 0.0, 0.0]
		inc   = []

		# freqs = []
		# freqs.push = Math.round((20 + i) * 190.73486328125) for i in [-5..5]

		for freq in freqs
			inc.push(2 * Math.PI * freq / @context.sampleRate)

		# Connect the node to a destination, i.e. the audio output.
		@node.onaudioprocess = (e) ->
			left  = e.outputBuffer.getChannelData(0)
			right = e.outputBuffer.getChannelData(1)

			numSamples = right.length
			for i in [0...numSamples]
				val = 0
				for j in [0...3]
					mag = if mags[j] < 0 then 0 else mags[j]
					val += mag * 0.001 * Math.sin(phase[j])
					phase[j] += inc[j]
				left[i] = val
				right[i] = val

		@node.connect(@context.destination);

	stop: ->
		@node.disconnect(@context.destination);

window.audio = new Audio()

########################################################################################	

