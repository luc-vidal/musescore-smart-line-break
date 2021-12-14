import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

/*
enum BarLineType {
	NORMAL = 1, SINGLE = BarLineType::NORMAL,
	DOUBLE = 2,
	START_REPEAT = 4, LEFT_REPEAT = BarLineType::START_REPEAT,
	END_REPEAT = 8, RIGHT_REPEAT = BarLineType::END_REPEAT,
	BROKEN = 0x10, DASHED = BarLineType::BROKEN,
	END = 0x20, FINAL = BarLineType::END,
	END_START_REPEAT = 0x40, LEFT_RIGHT_REPEAT = BarLineType::END_START_REPEAT,
	DOTTED = 0x80,
	REVERSE_END = 0x100, REVERSE_FINALE = BarLineType::REVERSE_END,
	HEAVY = 0x200,
	DOUBLE_HEAVY = 0x400
}

enum NoteType {
	NORMAL = 0,
	ACCIACCATURA = 0x1,
	APPOGGIATURA = 0x2,
	GRACE4 = 0x4,
	GRACE16 = 0x8,
	GRACE32 = 0x10,
	GRACE8_AFTER = 0x20,
	GRACE16_AFTER = 0x40,
	GRACE32_AFTER = 0x80,
	INVALID = 0xFF
}

*/

// TODO : Show MuseScore warning icon in warning dialog

MuseScore {
	menuPath: "Plugins.Smart line-break"
	version: "1.0"
	description: qsTr("Adds a line-break in the middle of a measure. A single normal note must be selected. This will split the measure before the note, decrement the measure number for the second half, add a dashed measure bar and a line-break.")

	MessageDialog {
		id: warningDialog
		visible: false
		title: qsTr("Warning")
		icon: StandardIcon.Warning
		text: ""
		standardButtons: StandardButton.Ok
		onAccepted: {
			Qt.quit();
		}
	}

	function warning(message) {
		warningDialog.text = message;
		warningDialog.visible = true;
	}

	onRun: {
 		// Check that we have a current score
		if (! curScore) {
			warning(qsTr("Please, open a score !"));
			return;
		}

 		// Check that we have a single normal note selected
		if (curScore.selection.elements.length !== 1) { // We want a single selection
			warning(qsTr("Please select a single normal note !"));
			return;
		}
		var selected = curScore.selection.elements[0];
		if (selected.type !== Element.NOTE && selected.type !== Element.REST) { // The selection must be a note or a rest
			warning(qsTr("Please select a single normal note !"));
			return;
		}

		if (selected.type === Element.NOTE && selected.noteType !=0) { // If the selection is a note, it must be a normal one (not a grace note). Cf. beginning of file for NoteType values.
			warning(qsTr("Please select a single normal note !"));
			return;
		}

		// Check that the selected note or rest isn't the first one in its measure
		var segment = curScore.selection.elements[0].parent;
		while (segment.type !== Element.SEGMENT) {
		    segment = segment.parent;
		}
		var tick = segment.tick;

		var cursor = curScore.newCursor();
		cursor.rewindToTick(tick);
		var currentMeasureTick = cursor.measure.firstSegment.tick;
		cursor.prev();
		if (cursor.measure === null || currentMeasureTick !== cursor.measure.firstSegment.tick) {
			warning(qsTr("Please do not select the first note of a measure !"));
			return;
		}

		// All is okay, let's add a smart line-break...
		curScore.startCmd()

		// Split measure
		cmd("split-measure");

		// Reduce second measure number
		cursor.rewindToTick(tick);
		cursor.measure.noOffset--;

		// Set dashed barline. Cf. beginning of file for BarLineType values
		cursor.filter = Segment.BarLineType;
		cursor.prev();
		cursor.element.barlineType = 0x10;

		// Add a line-break
		var lineBreak = newElement(Element.LAYOUT_BREAK);
		lineBreak.layoutBreakType = LayoutBreak.LINE;
		cursor.add(lineBreak);

		// Finished
		curScore.endCmd();

		Qt.quit();
	}
}
