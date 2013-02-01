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
				data.setValue i, j, value / 200.0
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
		zAxisHeader = "dB"
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
	
	$("#slider").slider
		value:255
		min: 1
		max: 500
		step: 1
		slide: (event, ui ) ->
			value = Math.round(parseInt(ui.value) * 190.73486328125)
			$("#frequency").html(value + " Hz")
	
	value = Math.round(255 * 190.73486328125)
	$("#frequency").html(value + " Hz")

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
		if window.audio.flag
			freq_index = $( "#slider" ).slider( "value" )
			mags = []
			mags.push(result.current[freq_index + i]) for i in [-1, 0, 1]
			console.log(mags.join(", "))
			window.audio.start(mags = [0.1, 0.1, 0.1])
								
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
			
		else if url is '/audio_start' or url is '/audio_stop'
			url = "#{url}.js"
			type = 'script'
			$.ajax
				type: 'GET'
				dataType: type
				url: url			

			value = $(@).text()
			if value is 'Sound Off'
				$(@).text("Sound On")
				$(@).data('ref', '/audio_stop')
			else
				$(@).text("Sound Off")
				$(@).data('ref', '/audio_start')
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
						# data.push(v)
					$('div#spectrogram').empty()
					$('#spectrogram').show()
					$('#angle').show()
					data = []
					for j in [0...60]
						temp = []
						for i in [0...500]
							temp.push(Math.floor(j))
							# temp.push(Math.floor(Math.random() * 60) + 1)
						data.push(temp)
					spectrogram(data, 'normal')
					spectral_data = data
						
			$('div#controls ul.buttons li.active').removeClass('active')
			$(@).addClass('active')
					
	
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
		freq_index = $( "#slider" ).slider( "value" )
		# Set up the per-sample phase increment based on the desired 
		# sine tone frequency and the sample rate of the audio context.
		# freqs = [523.25, 587.33, 659.26, 698.46, 784.00, 888.00, 987.6, 1046.5]
		# phase = [0.0,    0.0,    0.0,    0.0,    0.0,    0.0,    0.0,   0.0]
		# inc   = []


		# freqs = [523.25, 587.33, 659.26, 698.46, 784.00, 888.00, 987.6, 1046.5]
		freqs = [523.25, 587.33, 659.26]

		phase = [0.0,    0.0,    0.0]
		inc   = []

		# freqs = []
		# freqs.push = Math.round((freq_index + i) * 190.73486328125) for i in [-1, 0, 1]

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
					val += mags[j] * Math.sin(phase[j])
					phase[j] += inc[j]
				left[i] = val
				right[i] = val

		@node.connect(@context.destination);

	stop: ->
		@node.disconnect(@context.destination);

window.audio = new Audio()

########################################################################################	

########################################################################################	

