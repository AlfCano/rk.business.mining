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
  

function preview(){
	preprocess(true);
	calculate(true);
	printout(true);
}

function preprocess(is_preview){
	// add requirements etc. here
	if(is_preview) {
		echo("if(!base::require(rpart)){stop(" + i18n("Preview not available, because package rpart is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(rpart)\n");
	}	if(is_preview) {
		echo("if(!base::require(rpart.plot)){stop(" + i18n("Preview not available, because package rpart.plot is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(rpart.plot)\n");
	}
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var data = getValue('tree_data');
    var dep = parseVar(getValue('tree_dep'));
    var indep_raw = getValue('tree_indep');

    var minsplit = getValue('tree_minsplit');
    var maxdepth = getValue('tree_maxdepth');
    var cp = getValue('tree_cp');

    // Build the Formula: Target ~ Predictors
    var indep_str = '.';
    if (indep_raw !== '') {
        var indep_arr = indep_raw.split('\n').map(parseVar).filter(Boolean);
        if (indep_arr.length > 0) {
            indep_str = indep_arr.map(function(v){ return '`' + v + '`'; }).join(' + ');
        }
    }
    var formula = '`' + dep + '` ~ ' + indep_str;

    // Build the model
    echo('tree_model <- rpart::rpart(' + formula + ', data = ' + data + ', method = "class", ');
    echo('control = rpart::rpart.control(minsplit = ' + minsplit + ', maxdepth = ' + maxdepth + ', cp = ' + cp + '))\n\n');
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Decision Trees (Classification) results")).print();	
	}
    var p_type = getValue('tree_plot_type');
    var p_extra = getValue('tree_plot_extra');
    var p_pal = getValue('tree_plot_pal');

    // Comando 100% limpio (sin digits ni nn)
    var plot_cmd = 'rpart.plot::rpart.plot(tree_model, type = ' + p_type + ', extra = ' + p_extra + ', box.palette = "' + p_pal + '", shadow.col = "gray")';

    var w = getValue('tree_plot_w');
    var h = getValue('tree_plot_h');
    var res = getValue('tree_plot_res');

    if (typeof is_preview !== 'undefined' && is_preview) {
        // Truco Anti-Coma Decimal para el Preview
        echo('old_dec <- getOption("OutDec")\n');
        echo('options(OutDec = ".")\n');
        echo('try({' + plot_cmd + '}, silent=TRUE)\n');
        echo('options(OutDec = old_dec)\n');
    }

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("Business Analytics: Decision Tree Model")\n');

        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\n');

        // Truco Anti-Coma Decimal para la Salida Final
        echo('old_dec <- getOption("OutDec")\n');
        echo('options(OutDec = ".")\n');

        echo('try({\n  ' + plot_cmd + '\n');

        if (getValue('tree_save_plot.active')) {
            echo('  tree_plot <- recordPlot()\n');
        }
        echo('})\n');

        echo('options(OutDec = old_dec)\n'); // Restauramos la configuración original
        echo('rk.graph.off()\n\n');

        echo('rk.header("Model Summary & Variable Importance", level = 3)\n');
        echo('rk.print(tree_model$cptable)\n');
        echo('if (!is.null(tree_model$variable.importance)) {\n');
        echo('  rk.header("Variable Importance", level = 4)\n');
        echo('  rk.print(tree_model$variable.importance)\n');
        echo('}\n');

        if (getValue('tree_save_model.active') || getValue('tree_save_plot.active')) { echo('rk.print("<hr>")\n'); }
        if (getValue('tree_save_model.active')) { echo('rk.print(paste0("<b>Tree model saved as: </b><code>", "' + getValue('tree_save_model') + '", "</code><br>"))\n'); }
        if (getValue('tree_save_plot.active')) { echo('rk.print(paste0("<b>Plot object saved as: </b><code>", "' + getValue('tree_save_plot') + '", "</code>"))\n'); }
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var treeSaveModel = getValue("tree_save_model");
		var treeSaveModelActive = getValue("tree_save_model.active");
		var treeSaveModelParent = getValue("tree_save_model.parent");		var treeSavePlot = getValue("tree_save_plot");
		var treeSavePlotActive = getValue("tree_save_plot.active");
		var treeSavePlotParent = getValue("tree_save_plot.parent");
		// assign object to chosen environment
		if(treeSaveModelActive) {
			echo(".GlobalEnv$" + treeSaveModel + " <- tree_model\n");
		}
		if(treeSavePlotActive) {
			echo(".GlobalEnv$" + treeSavePlot + " <- tree_plot\n");
		}	
	}

}

