extends Node


func roundToTenExp(value: float, exponent: int):
	var multipleFactor = 10.0 ** exponent
	return (round(value / multipleFactor) * multipleFactor)


@warning_ignore("shadowed_global_identifier")
func valueAtPercentRange(percent: float, min: float, max: float):
	return (max - min) * percent + min


func grabBagProbability(list):
	if list.size() <= 1:
		return list[0]
	var grabBag = []
	var maxValue: int = -1
	for choice in list:
		maxValue += choice.chance
		grabBag.append(maxValue)
	var selectedValue = randi_range(0, maxValue)
	var c = 0
	while true:
		if selectedValue <= grabBag[c]:
			return list[c]
		c += 1


func weightedCoinProbability(heads: float, tails: float) -> bool:
	return randf_range(0, heads + tails) < heads


func getNext(array: Array, startIndex: int, condition: Callable):
	var testIndex = startIndex
	while testIndex < array.size():
		if (condition.call(array[testIndex])):
			return testIndex
		testIndex += 1
	return -1


func getPrevious(array: Array, rSearchIndex: int, condition: Callable):
	var testIndex = rSearchIndex
	while testIndex >= 0:
		if (condition.call(array[testIndex])):
			return testIndex
		testIndex -= 1
	return -1


func mapRange(array: Array, startIndex, EndIndex, mapFunction: Callable):
	var testIndex = startIndex
	var tally = 0
	while testIndex <= EndIndex:
		tally = mapFunction.call(array[testIndex])
		testIndex += 1
	return tally


func loadSave():
#	setDefaultSave()
	if ResourceLoader.exists("user://userData.tres") && load("user://userData.tres") is saveData:
		print("Loading Existing Save")
		return load("user://userData.tres")
	else:
		print("Creating New Save")
		setDefaultSave()
		return load("user://userData.tres")


func getSessionSettings():
	var outputDictionary: Dictionary = {}
	var fullSettings = loadSave().settings
	outputDictionary.merge(fullSettings.generalSettings, true)
	outputDictionary.merge(fullSettings.generationPresets[outputDictionary.generationPreset], true)
	return outputDictionary


func setDefaultSave():
	var save = saveData.new()
	save.settings = {
		"generalSettings": {
			"generationPreset": "Easy",
			"genPresetOrder": ["Easy", "Medium", "Hard", "Challenging"],
			"sequenceLength": 4,
			
			"noteScale": .2,
			"feedbackDisplayHeight": .07,
			"buttonSize": .1,
			"topMargin": .05,
			"sideMargin": .1,
			"notePadding": .05,
			"buttonMargin": .03,
			
			"inputCalibration": -24,
			"audioCalibration": -17,
			"releaseWindow": 0.25,
			"pressWindow": 0.15,
			"metronomeOn": true,
			"metronomeVolume": 1.0,
			"showMetronome": true,
			"countInMeasures": 1,
			"manualCountIn": false,
			"BPM": 90,
			"highlightCurrentMeasure": true
		},
		"generationPresets": {
			"Easy": {
				"divProb": [0.04, 0.2, 0.4, 0.1, 0],
				"noteProb": [1, 0.8, 0.7, 0.9, 0.85],
				"tripletProb": [0, 0, 0, 0, 0],
				"tiedProb": [0.3, 0.3, 0.3, 0.3, 0.2],
				"syncoProb": [0, 0.2, 0.5, 1, 1],
				"tieOverMeasureProb": 0,
				"sigChangeProb": 0,
				"sigList": [
					{
						"numerator": 4,
						"denominator": 4,
						"chance": 100
					},
					{
						"numerator": 3,
						"denominator": 4,
						"chance": 50
					},
				]
			},
			"Medium": {
				"divProb": [0.01, 0.2, 0.4, 0.6, 0],
				"noteProb": [1, 0.8, 0.7, 0.7, 1],
				"tripletProb": [0, 0, 0, 0, 0],
				"tiedProb": [0.3, 0.3, 0.3, 0.3, 0.2],
				"syncoProb": [0, 0.2, 0.5, 1, 1],
				"tieOverMeasureProb": .05,
				"sigChangeProb": 0,
				"sigList": [
					{
						"numerator": 4,
						"denominator": 4,
						"chance": 50
					},
					{
						"numerator": 3,
						"denominator": 4,
						"chance": 50
					},
				]
			},
			"Hard": {
				"divProb": [0, 0.05, 0.2, 0.2, 0.1],
				"noteProb": [1, 0.8, 0.7, 0.7, 0.8],
				"tripletProb": [0, 0, 0, .05, 0],
				"tiedProb": [0.4, 0.4, 0.4, 0.4, 0.2],
				"syncoProb": [0, 0.2, 0.5, 1, 1],
				"tieOverMeasureProb": .05,
				"sigChangeProb": .06,
				"sigList": [
					{
						"numerator": 4,
						"denominator": 4,
						"chance": 50
					},
					{
						"numerator": 3,
						"denominator": 4,
						"chance": 50
					},
				]
			},
			"Challenging": {
				"divProb": [0, 0.1, 0.1, 0.2, 0.2],
				"noteProb": [1, 0.8, 0.7, 0.7, 0.7],
				"tripletProb": [0, 0, 0.05, .1, 0],
				"tiedProb": [0.4, 0.4, 0.4, 0.4, 0.4],
				"syncoProb": [0, 0.2, 0.5, 1, 1],
				"tieOverMeasureProb": .1,
				"sigChangeProb": 0.1,
				"sigList": [
					{
						"numerator": 4,
						"denominator": 4,
						"chance": 50
					},
					{
						"numerator": 3,
						"denominator": 4,
						"chance": 50
					},
					{
						"numerator": 5,
						"denominator": 4,
						"chance": 20
					},
				]
			},
		}
	}
	save.tutorials = {
		"feedback": true,
		"manualCountIn": true,
		"welcome": true,
		"tapHint": true
		}
	ResourceSaver.save(save, "user://userData.tres")

const graphicData = {
	"note": {
		"unbeamed": {
			4 as float: {
				"path": "res://Notation/wholeNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": 4,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
			2 as float: {
				"path": "res://Notation/halfNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": 2,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
			1 as float: {
				"path": "res://Notation/quarterNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": 1.5,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
			.5 as float: {
				"path": "res://Notation/eighthNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": 1.25,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
			.25 as float: {
				"path": "res://Notation/sixteenthNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": 1.25,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
		},
		"beamed": {
			4 as float: {
				"path": "res://Notation/quarterNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": 4,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
			2 as float: {
				"path": "res://Notation/quarterNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": 2,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
			1 as float: {
				"path": "res://Notation/quarterNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": 1.5,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
			.5 as float: {
				"path": "res://Notation/quarterNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": 1.15,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
			.25 as float: {
				"path": "res://Notation/quarterNote.png",
				"dimensions": Vector2i(768, 1248),
				"offset": Vector2i(0, 0),
				"xIncrimentRatio": .9,
				"frontMarker": 192,
				"backMarker": 384,
				"dotPosition": Vector2i(500, 1092)
			},
		}
	},
	"rest": {
		4 as float: {
			"path": "res://Notation/wholeRest.png",
			"dimensions": Vector2i(768, 1248),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 4,
			"frontMarker": 0,
			"backMarker": 384,
			"dotPosition": Vector2i(500, 624)
		},
		2 as float: {
			"path": "res://Notation/halfRest.png",
			"dimensions": Vector2i(768, 1248),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 2,
			"frontMarker": 0,
			"backMarker": 384,
			"dotPosition": Vector2i(500, 624)
		},
		1 as float: {
			"path": "res://Notation/quarterRest.png",
			"dimensions": Vector2i(768, 1248),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 1,
			"frontMarker": 0,
			"backMarker": 384,
			"dotPosition": Vector2i(500, 624)
		},
		.5 as float: {
			"path": "res://Notation/eighthRest.png",
			"dimensions": Vector2i(768, 1248),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": .8,
			"frontMarker": 0,
			"backMarker": 384,
			"dotPosition": Vector2i(500, 624)
		},
		.25 as float: {
			"path": "res://Notation/sixteenthRest.png",
			"dimensions": Vector2i(768, 1248),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": .8,
			"frontMarker": 0,
			"backMarker": 384,
			"dotPosition": Vector2i(500, 624)
		}
	},
	"tuplet": {
		3: {
			"path": "res://Notation/tuplet3.png",
			"dimensions": Vector2i(192, 288),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 192,
		},
		"placeHolder": {
			"path": "",
			"dimensions": Vector2i(192, 288),
			"offset": Vector2i(0, -312),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 192,
		},
		"bar": {
			"path": "res://Notation/tupletBar.png",
			"dimensions": Vector2i(384, 288),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 384,
		},
		"brace": {
			"path": "res://Notation/tupletBrace.png",
			"dimensions": Vector2i(96, 288),
			"offset": Vector2i(0, -312),
			"xIncrimentRatio": 0,
			"frontMarker": 48,
			"backMarker": 48,
		}
	},
	"tie": {
		"path": "res://Notation/tie.png",
		"dimensions": Vector2i(764, 86),
		"offset": Vector2i(0, 0),
		"xIncrimentRatio": 0,
		"frontMarker": 0,
		"backMarker": 764,
	},
	"beam": {
		1: {
			"path": "res://Notation/beam1.png",
			"dimensions": Vector2i(384, 1248),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 384,
		},
		2: {
			"path": "res://Notation/beam2.png",
			"dimensions": Vector2i(384, 1248),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 384,
		},
		3: {
			"path": "res://Notation/3.png",
			"dimensions": Vector2i(384, 1248),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 384,
		},
		4: {
			"path": "res://Notation/4.png",
			"dimensions": Vector2i(384, 1248),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 384,
		}
	},
	"timeSignature": {
		1: {
			"path": "res://Notation/timeSignature1.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		2: {
			"path": "res://Notation/timeSignature2.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		3: {
			"path": "res://Notation/timeSignature3.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		4: {
			"path": "res://Notation/timeSignature4.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		5: {
			"path": "res://Notation/timeSignature5.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		6: {
			"path": "res://Notation/timeSignature6.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		7: {
			"path": "res://Notation/timeSignature7.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		8: {
			"path": "res://Notation/timeSignature8.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		9: {
			"path": "res://Notation/timeSignature9.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		10: {
			"path": "res://Notation/timeSignature10.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		11: {
			"path": "res://Notation/timeSignature11.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		12: {
			"path": "res://Notation/timeSignature12.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
		16: {
			"path": "res://Notation/timeSignature16.png",
			"dimensions": Vector2i(768, 624),
			"offset": Vector2i(0, 0),
			"xIncrimentRatio": 0,
			"frontMarker": 0,
			"backMarker": 768,
		},
	},
	"dot": {
		"path": "res://Notation/dot.png",
		"dimensions": Vector2i(192, 192),
		"offset": Vector2i(0, -96),
		"xIncrimentRatio": 1.5,
		"frontMarker": 0,
		"backMarker": 96,
		"dotPosition": Vector2i(192, 96)
	},
	"measureLine": {
		"path": "res://Notation/measureLine.png",
		"dimensions": Vector2i(768, 1439),
		"offset": Vector2i(0, -96),
		"xIncrimentRatio": .5,
		"frontMarker": 0,
		"backMarker": 384,
	}
}
