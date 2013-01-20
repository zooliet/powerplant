# $("div.box").append("<p>coffee response</p>")
# $("div#surfacePlotDiv").empty()
# google.load "visualization", "1"
# google.setOnLoadCallback surface_setup
# 
# surface_draw = ->
# 	alert("Setup is called and Plot is about to start...")
# 	
# 	numRows = 45.0
# 	numCols = 45
# 	tooltipStrings = new Array()
# 	data = new google.visualization.DataTable()
# 	
# 	i = 0
# 	while i < numCols
# 		data.addColumn "number", "col" + i
# 		i++
# 	data.addRows numRows
# 	d = 360 / numRows
# 	idx = 0
# 	i = 0
# 	while i < numRows
# 		j = 0
# 		while j < numCols
# 			value = (Math.sin(i * d * Math.PI / 180.0))
# 			data.setValue i, j, value / 4.0
# 			tooltipStrings[idx] = "x:" + i + ", y:" + j + " = " + value
# 			idx++
# 			j++
# 		i++
# 	
# 	surfacePlot = new greg.ross.visualisation.SurfacePlot(document.getElementById("surfacePlotDiv"))
# 	# Don't fill polygons in IE. It's too slow.
# 	fillPly = false
# 	# Define a colour gradient.
# 	colour1 =
# 		red: 0
# 		green: 0
# 		blue: 255
# 	colour2 =
# 		red: 0
# 		green: 255
# 		blue: 255
# 	colour3 =
# 		red: 0
# 		green: 255
# 		blue: 0
# 	colour4 =
# 		red: 255
# 		green: 255
# 		blue: 0
# 	colour5 =
# 		red: 255
# 		green: 0
# 		blue: 0
# 	colours = [colour1, colour2, colour3, colour4, colour5]
# 	# Axis labels.
# 	xAxisHeader = "X"
# 	yAxisHeader = "Y"
# 	zAxisHeader = "Z"
# 	options =
# 		xPos: 300
# 		yPos: 50
# 		width: 500
# 		height: 500
# 		colourGradient: colours
# 		fillPolygons: fillPly
# 		tooltips: tooltipStrings
# 		xTitle: xAxisHeader
# 		yTitle: yAxisHeader
# 		zTitle: zAxisHeader
# 	
# 	alert("Setup is called and Plot is about to start...")	
# 	surfacePlot.draw data, options

# surface_draw()