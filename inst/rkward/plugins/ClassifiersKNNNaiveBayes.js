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
	echo("require(caret)\n");	echo("require(e1071)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var data = getValue('cls_data');
    var dep = parseVar(getValue('cls_dep'));
    var indep_raw = getValue('cls_indep');
    var algo = getValue('cls_type');
    var is_scale = getValue('knn_scale');

    var indep_str = '.';
    if (indep_raw !== '') {
        var indep_arr = indep_raw.split('\n').map(parseVar).filter(Boolean);
        if (indep_arr.length > 0) { indep_str = indep_arr.map(function(v){ return '`' + v + '`'; }).join(' + '); }
    }
    var formula = '`' + dep + '` ~ ' + indep_str;

    if (algo === 'knn') {
        var k = getValue('knn_k');
        if (is_scale === 'TRUE') {
            echo('my_model <- caret::train(' + formula + ', data = ' + data + ', method = "knn", tuneGrid = data.frame(k = ' + k + '), preProcess = c("center", "scale"))\n');
        } else {
            echo('my_model <- caret::knn3(' + formula + ', data = ' + data + ', k = ' + k + ')\n');
        }
    } else {
        echo('my_model <- e1071::naiveBayes(' + formula + ', data = ' + data + ')\n');
    }
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Classifiers (KNN & Naive Bayes) results")).print();

    var algo = getValue('cls_type');

    // CORRECCIÓN: Envolver los comandos de R dentro de echo()
    if (algo === 'knn') {
        echo('rk.header("K-Nearest Neighbors (KNN) Model")\n');
    } else {
        echo('rk.header("Naive Bayes Model")\n');
    }

    echo('rk.print(my_model)\n');

    if (getValue('cls_save_model.active')) {
        echo('rk.print(paste0("<hr><b>Model saved as: </b><code>", "' + getValue('cls_save_model') + '", "</code>"))\n');
    }
  
	//// save result object
	// read in saveobject variables
	var clsSaveModel = getValue("cls_save_model");
	var clsSaveModelActive = getValue("cls_save_model.active");
	var clsSaveModelParent = getValue("cls_save_model.parent");
	// assign object to chosen environment
	if(clsSaveModelActive) {
		echo(".GlobalEnv$" + clsSaveModel + " <- my_model\n");
	}

}

