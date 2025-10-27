extends Node

const SAVE_PATH = "user://userData.tres"

func loadSave():
	if ResourceLoader.exists(SAVE_PATH):
		return load(SAVE_PATH)
	else:
		return createDefaultSave()

func createDefaultSave():
	var save = saveData.new()
	save.settings = createDefaultSettings()
	save.tutorials = createDefaultTutorials()
	return save

func createDefaultSettings():
	return {
		"generalSettings": {
			"noteScale": 0.15,
			"feedbackDisplayHeight": 0.12,
			"buttonSize": 0.1,
			"topMargin": 0.05,
			"notePadding": 0.02,
			"sideMargin": 0.05,
			"buttonMargin": 0.02,
			"inputCalibration": 0,
			"audioCalibration": 0,
			"sequenceLength": 4,
			"releaseWindow": 0.2,
			"pressWindow": 0.2,
			"metronomeOn": true,
			"metronomeVolume": 0.5,
			"showMetronome": true,
			"countInMeasures": 1,
			"manualCountIn": false,
			"BPM": 120,
			"highlightCurrentMeasure": true,
			"generationPreset": 0,
			"genPresetOrder": [0]
		},
		"generationPresets": {}
	}

func createDefaultTutorials():
	return {
		"tapHint": true,
		"welcome": true,
		"manualCountIn": true,
		"feedback": true
	}
