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
		echo("if(!base::require(caret)){stop(" + i18n("Preview not available, because package caret is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(caret)\n");
	}	if(is_preview) {
		echo("if(!base::require(pROC)){stop(" + i18n("Preview not available, because package pROC is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(pROC)\n");
	}
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var t_data = getValue('eval_data');
    var t_target = parseVar(getValue('eval_target'));
    var m_obj = getValue('eval_model');

    echo('test_df <- ' + t_data + '\n');
    echo('actual_labels <- test_df[["' + t_target + '"]]\n');
    echo('if (!is.factor(actual_labels)) actual_labels <- as.factor(actual_labels)\n\n');

    echo('# Predict Classes\n');
    echo('pred_class <- predict(' + m_obj + ', newdata = test_df, type = "class")\n');
    echo('if (inherits(' + m_obj + ', "train")) pred_class <- predict(' + m_obj + ', newdata = test_df)\n\n'); // Fix for caret KNN

    if (getValue('eval_chk_cm') === 'TRUE') {
        echo('conf_mat <- caret::confusionMatrix(pred_class, actual_labels)\n');
    }

    if (getValue('eval_chk_roc') === 'TRUE') {
        echo('# Predict Probabilities for ROC\n');
        echo('if (inherits(' + m_obj + ', "naiveBayes")) {\n');
        echo('  pred_prob <- predict(' + m_obj + ', newdata = test_df, type = "raw")\n');
        echo('} else {\n');
        echo('  pred_prob <- predict(' + m_obj + ', newdata = test_df, type = "prob")\n');
        echo('}\n');
        echo('# Take probabilities of the second class (assumed positive)\n');
        echo('prob_pos <- pred_prob[, 2]\n');
        echo('roc_obj <- pROC::roc(response = actual_labels, predictor = prob_pos, quiet = TRUE)\n');
    }
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Model Evaluation (ROC & CM) results")).print();	
	}
    // 1. Apagamos los ejes automáticos de R (xaxt='n', yaxt='n')
    var plot_cmd = 'plot(roc_obj, col = "#0055A4", main = "ROC Curve", lwd = 2, print.auc = TRUE, legacy.axes = TRUE, xaxt = "n", yaxt = "n")';

    // 2. Dibujamos manualmente los ejes con números perfectos y redondeados
    var axes_cmd = 'axis(1, at = seq(0, 1, by = 0.2), labels = c("0.0", "0.2", "0.4", "0.6", "0.8", "1.0"))\n' +
                   'axis(2, at = seq(0, 1, by = 0.2), labels = c("0.0", "0.2", "0.4", "0.6", "0.8", "1.0"))';

    // Lógica del PREVIEW (Live Preview)
    if (typeof is_preview !== 'undefined' && is_preview) {
        if (getValue('eval_chk_roc') === 'TRUE') {
            echo(plot_cmd + '\n');
            echo(axes_cmd + '\n');
        }
    }

    // Lógica de Salida Final (HTML)
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("Model Evaluation Results")\n');

        if (getValue('eval_chk_cm') === 'TRUE') {
            echo('rk.header("Confusion Matrix & Business Metrics", level = 3)\n');
            echo('rk.print(conf_mat$table)\n');
            echo('rk.print(conf_mat$byClass)\n');
            echo('rk.print(paste("<b>Overall Accuracy:</b>", round(conf_mat$overall["Accuracy"], 4)))\n');
        }

        if (getValue('eval_chk_roc') === 'TRUE') {
            echo('rk.header("ROC Curve & AUC", level = 3)\n');
            echo('rk.print(paste("<b>Area Under Curve (AUC):</b>", round(roc_obj$auc, 4)))\n');

            echo('rk.graph.on(width = ' + getValue('eval_plot_w') + ', height = ' + getValue('eval_plot_h') + ')\n');

            // Ejecutamos el gráfico y luego le agregamos los ejes hermosos
            echo(plot_cmd + '\n');
            echo(axes_cmd + '\n');

            echo('rk.graph.off()\n');
        }
    }
  

}

