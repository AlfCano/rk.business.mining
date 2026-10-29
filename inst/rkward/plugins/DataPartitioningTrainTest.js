// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

// define variables globally
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"');
    }

    function parseVar(fullPath) {
        if (!fullPath) return '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/["']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            raw_col = fullPath.split('$')[1];
        } else {
            raw_col = fullPath;
        }
        return raw_col;
    }
  



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(caret)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var data = getValue('part_data');
    var target = parseVar(getValue('part_target'));
    var prop = getValue('part_prop') / 100;

    if (getValue('part_seed_chk') === 'TRUE') {
        echo('set.seed(' + getValue('part_seed_val') + ')\n\n');
    }

    // Use caret to create a stratified partition (maintains the ratio of the target variable)
    echo('train_idx <- caret::createDataPartition(' + data + '[["' + target + '"]], p = ' + prop + ', list = FALSE)\n');

    echo('data_train <- ' + data + '[train_idx, ]\n');
    echo('data_test <- ' + data + '[-train_idx, ]\n\n');
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Data Partitioning (Train/Test) results")).print();

    echo('rk.header("Data Partitioning (Train/Test Split)")\n');

    echo('rk.print(paste("<b>Original dataset rows:</b>", nrow(' + getValue('part_data') + ')))\n');
    echo('rk.print(paste("<b>Training set rows:</b>", nrow(data_train), "(", round((nrow(data_train)/nrow(' + getValue('part_data') + '))*100, 1), "% )"))\n');
    echo('rk.print(paste("<b>Testing set rows:</b>", nrow(data_test), "(", round((nrow(data_test)/nrow(' + getValue('part_data') + '))*100, 1), "% )"))\n');

    echo('rk.print("<hr>")\n');
    if (getValue('part_save_train.active')) { echo('rk.print(paste0("<b>Training data saved as: </b><code>", "' + getValue('part_save_train') + '", "</code><br>"))\n'); }
    if (getValue('part_save_test.active')) { echo('rk.print(paste0("<b>Testing data saved as: </b><code>", "' + getValue('part_save_test') + '", "</code>"))\n'); }
  
	//// save result object
	// read in saveobject variables
	var partSaveTrain = getValue("part_save_train");
	var partSaveTrainActive = getValue("part_save_train.active");
	var partSaveTrainParent = getValue("part_save_train.parent");	var partSaveTest = getValue("part_save_test");
	var partSaveTestActive = getValue("part_save_test.active");
	var partSaveTestParent = getValue("part_save_test.parent");
	// assign object to chosen environment
	if(partSaveTrainActive) {
		echo(".GlobalEnv$" + partSaveTrain + " <- data_train\n");
	}
	if(partSaveTestActive) {
		echo(".GlobalEnv$" + partSaveTest + " <- data_test\n");
	}

}

