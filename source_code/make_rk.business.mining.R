local({
  # =========================================================================================
  # 1. Setup and Metadata
  # =========================================================================================
  require(rkwarddev)

  plugin_name <- "rk.business.mining"

  about_info <- rk.XML.about(
    name = plugin_name,
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "Business Analytics & Data Mining: Partitioning, Decision Trees, and Classification",
      version = "0.0.1",
      url = "https://github.com/AlfCano/rk.business.mining",
      license = "GPL (>= 3)"
    )
  )

  dependencies_node <- rk.XML.dependencies(
    dependencies = list(R.min = "4.0.0"),
    package = list(
      c(name = "rpart"),
      c(name = "rpart.plot"),
      c(name = "caret"),
      c(name = "e1071"),
      c(name = "pROC")
    )
  )

  # Menu hierarchy: Analysis -> Predictive Analytics
  h_mining <- list("analysis", "Predictive Analytics")

  # Global JavaScript Helper Functions
  js_helpers <- "
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, \"\\\\'\").replace(/\"/g, '\\\\\"');
    }

    function parseVar(fullPath) {
        if (!fullPath) return '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/[\"']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            raw_col = fullPath.split('$')[1];
        } else {
            raw_col = fullPath;
        }
        return raw_col;
    }
  "

  # =========================================================================================
  # 2. MAIN COMPONENT: Decision Trees (rpart)
  # =========================================================================================

  # --- UI Elements ---
  tree_vs <- rk.XML.varselector(id.name = "tree_vs")
  tree_data <- rk.XML.varslot("Training Data (data.frame)", source = "tree_vs", classes = "data.frame", required = TRUE, id.name = "tree_data")
  tree_dep <- rk.XML.varslot("Target Variable (Dependent)", source = "tree_vs", required = TRUE, id.name = "tree_dep")
  tree_indep <- rk.XML.varslot("Predictors (Leave empty for all remaining)", source = "tree_vs", multi = TRUE, required = FALSE, id.name = "tree_indep")

  # Model Complexity (Hyperparameters)
  tree_minsplit <- rk.XML.spinbox("Minimum observations to split a node (minsplit)", min = 1, max = 10000, initial = 20, real = FALSE, id.name = "tree_minsplit")
  tree_maxdepth <- rk.XML.spinbox("Maximum Tree Depth (maxdepth)", min = 1, max = 30, initial = 10, real = FALSE, id.name = "tree_maxdepth")
  tree_cp <- rk.XML.spinbox("Complexity Parameter (cp - for pruning)", min = 0, max = 1, initial = 0.01, real = TRUE, id.name = "tree_cp")
  frm_hyper <- rk.XML.frame(tree_minsplit, tree_maxdepth, tree_cp, label = "Hyperparameters (Complexity Control)")

  # Plot Customization (The "Wow" Effect via rpart.plot)
  tree_plot_type <- rk.XML.dropdown("Plot Type", options = list(
    "Standard (Labels below nodes)" = list(val = "2", chk = TRUE),
    "Compact (Left/Right split labels)" = list(val = "3"),
    "Detailed (Interior nodes)" = list(val = "4")
  ), id.name = "tree_plot_type")

  tree_plot_extra <- rk.XML.dropdown("Extra Information in Nodes", options = list(
    "Class Probabilities & Node Percentage" = list(val = "104", chk = TRUE),
    "Counts for each class" = list(val = "2"),
    "Just the predicted class" = list(val = "0")
  ), id.name = "tree_plot_extra")

  tree_plot_pal <- rk.XML.dropdown("Color Palette", options = list(
    "Red-Yellow-Green (Business)" = list(val = "RdYlGn", chk = TRUE),
    "Blues" = list(val = "Blues"),
    "Greens" = list(val = "Greens"),
    "Grayscale" = list(val = "Greys")
  ), id.name = "tree_plot_pal")

  frm_plot <- rk.XML.frame(tree_plot_type, tree_plot_extra, tree_plot_pal, label = "Visual Appearance (rpart.plot)")

  # Output Options
  tree_plot_w <- rk.XML.spinbox("HTML Plot Width (pixels)", min = 100, max = 5000, initial = 800, real = FALSE, id.name = "tree_plot_w")
  tree_plot_h <- rk.XML.spinbox("HTML Plot Height (pixels)", min = 100, max = 5000, initial = 600, real = FALSE, id.name = "tree_plot_h")
  tree_plot_res <- rk.XML.spinbox("Resolution (DPI)", min = 72, max = 600, initial = 120, real = FALSE, id.name = "tree_plot_res")
  frm_tree_graph_size <- rk.XML.frame(rk.XML.row(tree_plot_w, tree_plot_h, tree_plot_res), label = "Graphics Size & Resolution")

  tree_save_model <- rk.XML.saveobj("Save Decision Tree Model as", initial = "tree_model", chk = TRUE, id.name = "tree_save_model")
  tree_save_plot <- rk.XML.saveobj("Save Plot as R Object", initial = "tree_plot", chk = FALSE, id.name = "tree_save_plot")

  tree_preview <- rk.XML.preview(label = "Preview Decision Tree Plot")

  # Layout logic
  logic_tree <- rk.XML.logic(rk.XML.connect(governor = tree_data, get = "available", client = tree_vs, set = "root"))

  tab_tree <- rk.XML.tabbook(tabs = list(
    "Variables & Data" = rk.XML.col(tree_data, tree_dep, tree_indep, rk.XML.stretch()),
    "Hyperparameters" = rk.XML.col(frm_hyper, rk.XML.stretch()),
    "Plot Options" = rk.XML.col(frm_plot, rk.XML.stretch()),
    "Output" = rk.XML.col(frm_tree_graph_size, tree_save_model, tree_save_plot, tree_preview, rk.XML.stretch())
  ))

  dialog_tree <- rk.XML.dialog(rk.XML.row(tree_vs, rk.XML.col(tab_tree)), label = "Decision Trees (Classification & Regression)")

  # JavaScript Logic
  js_calc_tree <- "
    var data = getValue('tree_data');
    var dep = parseVar(getValue('tree_dep'));
    var indep_raw = getValue('tree_indep');

    var minsplit = getValue('tree_minsplit');
    var maxdepth = getValue('tree_maxdepth');
    var cp = getValue('tree_cp');

    // Build the Formula: Target ~ Predictors
    var indep_str = '.';
    if (indep_raw !== '') {
        var indep_arr = indep_raw.split('\\n').map(parseVar).filter(Boolean);
        if (indep_arr.length > 0) {
            indep_str = indep_arr.map(function(v){ return '`' + v + '`'; }).join(' + ');
        }
    }
    var formula = '`' + dep + '` ~ ' + indep_str;

    // Build the model
    echo('tree_model <- rpart::rpart(' + formula + ', data = ' + data + ', method = \"class\", ');
    echo('control = rpart::rpart.control(minsplit = ' + minsplit + ', maxdepth = ' + maxdepth + ', cp = ' + cp + '))\\n\\n');
  "


  js_print_tree <- "
    var p_type = getValue('tree_plot_type');
    var p_extra = getValue('tree_plot_extra');
    var p_pal = getValue('tree_plot_pal');

    // Comando 100% limpio (sin digits ni nn)
    var plot_cmd = 'rpart.plot::rpart.plot(tree_model, type = ' + p_type + ', extra = ' + p_extra + ', box.palette = \"' + p_pal + '\", shadow.col = \"gray\")';

    var w = getValue('tree_plot_w');
    var h = getValue('tree_plot_h');
    var res = getValue('tree_plot_res');

    if (typeof is_preview !== 'undefined' && is_preview) {
        // Truco Anti-Coma Decimal para el Preview
        echo('old_dec <- getOption(\"OutDec\")\\n');
        echo('options(OutDec = \".\")\\n');
        echo('try({' + plot_cmd + '}, silent=TRUE)\\n');
        echo('options(OutDec = old_dec)\\n');
    }

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"Business Analytics: Decision Tree Model\")\\n');

        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\\n');

        // Truco Anti-Coma Decimal para la Salida Final
        echo('old_dec <- getOption(\"OutDec\")\\n');
        echo('options(OutDec = \".\")\\n');

        echo('try({\\n  ' + plot_cmd + '\\n');

        if (getValue('tree_save_plot.active')) {
            echo('  tree_plot <- recordPlot()\\n');
        }
        echo('})\\n');

        echo('options(OutDec = old_dec)\\n'); // Restauramos la configuración original
        echo('rk.graph.off()\\n\\n');

        echo('rk.header(\"Model Summary & Variable Importance\", level = 3)\\n');
        echo('rk.print(tree_model$cptable)\\n');
        echo('if (!is.null(tree_model$variable.importance)) {\\n');
        echo('  rk.header(\"Variable Importance\", level = 4)\\n');
        echo('  rk.print(tree_model$variable.importance)\\n');
        echo('}\\n');

        if (getValue('tree_save_model.active') || getValue('tree_save_plot.active')) { echo('rk.print(\"<hr>\")\\n'); }
        if (getValue('tree_save_model.active')) { echo('rk.print(paste0(\"<b>Tree model saved as: </b><code>\", \"' + getValue('tree_save_model') + '\", \"</code><br>\"))\\n'); }
        if (getValue('tree_save_plot.active')) { echo('rk.print(paste0(\"<b>Plot object saved as: </b><code>\", \"' + getValue('tree_save_plot') + '\", \"</code>\"))\\n'); }
    }
  "

  # =========================================================================================
  # 3. SECONDARY COMPONENT: Data Partitioning (Train/Test Split)
  # =========================================================================================

  part_vs <- rk.XML.varselector(id.name = "part_vs")
  part_data <- rk.XML.varslot("Dataset to Partition", source = "part_vs", classes = "data.frame", required = TRUE, id.name = "part_data")
  part_target <- rk.XML.varslot("Target Variable (For Stratified Sampling)", source = "part_vs", required = TRUE, id.name = "part_target")

  part_prop <- rk.XML.spinbox("Percentage for Training Data", min = 10, max = 95, initial = 70, real = FALSE, id.name = "part_prop")

  part_seed_chk <- rk.XML.cbox("Set Random Seed (for reproducibility)", value = "TRUE", chk = TRUE, id.name = "part_seed_chk")
  part_seed_val <- rk.XML.spinbox("Seed Value", min = 1, max = 999999, initial = 12345, real = FALSE, id.name = "part_seed_val")
  frm_seed <- rk.XML.frame(part_seed_chk, part_seed_val, label = "Reproducibility")

  part_save_train <- rk.XML.saveobj("Save Training Data as", initial = "data_train", chk = TRUE, id.name = "part_save_train")
  part_save_test <- rk.XML.saveobj("Save Testing Data as", initial = "data_test", chk = TRUE, id.name = "part_save_test")
  frm_part_save <- rk.XML.frame(part_save_train, part_save_test, label = "Export Subsets to Workspace")

  logic_part <- rk.XML.logic(
    rk.XML.connect(governor = part_data, get = "available", client = part_vs, set = "root"),

    rk.XML.connect(governor = part_seed_chk, get = "state", client = part_seed_val, set = "enabled")
  )

  dialog_part <- rk.XML.dialog(
    rk.XML.row(
      part_vs,
      rk.XML.col(
        part_data,
        part_target,
        part_prop,
        frm_seed,
        frm_part_save,
        rk.XML.stretch()
      )
    ),
    label = "Data Partitioning (Train / Test Split)"
  )

  js_calc_part <- "
    var data = getValue('part_data');
    var target = parseVar(getValue('part_target'));
    var prop = getValue('part_prop') / 100;

    if (getValue('part_seed_chk') === 'TRUE') {
        echo('set.seed(' + getValue('part_seed_val') + ')\\n\\n');
    }

    // Use caret to create a stratified partition (maintains the ratio of the target variable)
    echo('train_idx <- caret::createDataPartition(' + data + '[[\"' + target + '\"]], p = ' + prop + ', list = FALSE)\\n');

    echo('data_train <- ' + data + '[train_idx, ]\\n');
    echo('data_test <- ' + data + '[-train_idx, ]\\n\\n');
  "

  js_print_part <- "
    echo('rk.header(\"Data Partitioning (Train/Test Split)\")\\n');

    echo('rk.print(paste(\"<b>Original dataset rows:</b>\", nrow(' + getValue('part_data') + ')))\\n');
    echo('rk.print(paste(\"<b>Training set rows:</b>\", nrow(data_train), \"(\", round((nrow(data_train)/nrow(' + getValue('part_data') + '))*100, 1), \"% )\"))\\n');
    echo('rk.print(paste(\"<b>Testing set rows:</b>\", nrow(data_test), \"(\", round((nrow(data_test)/nrow(' + getValue('part_data') + '))*100, 1), \"% )\"))\\n');

    echo('rk.print(\"<hr>\")\\n');
    if (getValue('part_save_train.active')) { echo('rk.print(paste0(\"<b>Training data saved as: </b><code>\", \"' + getValue('part_save_train') + '\", \"</code><br>\"))\\n'); }
    if (getValue('part_save_test.active')) { echo('rk.print(paste0(\"<b>Testing data saved as: </b><code>\", \"' + getValue('part_save_test') + '\", \"</code>\"))\\n'); }
  "

  comp_partition <- rk.plugin.component(
    "Data Partitioning (Train/Test)",
    xml = list(dialog = dialog_part, logic = logic_part),
    js = list(require = c("caret"), globals = js_helpers, calculate = js_calc_part, printout = js_print_part),
    hierarchy = h_mining
  )

  # =========================================================================================
  # 3A. COMPONENT: KNN & Naive Bayes
  # =========================================================================================
  cls_vs <- rk.XML.varselector(id.name = "cls_vs")
  cls_data <- rk.XML.varslot("Training Data", source = "cls_vs", classes = "data.frame", required = TRUE, id.name = "cls_data")
  cls_dep <- rk.XML.varslot("Target Variable", source = "cls_vs", required = TRUE, id.name = "cls_dep")
  cls_indep <- rk.XML.varslot("Predictors (Empty for all)", source = "cls_vs", multi = TRUE, required = FALSE, id.name = "cls_indep")

  cls_type <- rk.XML.radio("Classifier Algorithm", options = list(
    "K-Nearest Neighbors (KNN)" = list(val = "knn", chk = TRUE),
    "Naive Bayes" = list(val = "nb")
  ), id.name = "cls_type")

  knn_k <- rk.XML.spinbox("Number of Neighbors (k)", min = 1, max = 100, initial = 5, real = FALSE, id.name = "knn_k")
  knn_scale <- rk.XML.cbox("Standardize (Scale) numeric data?", value = "TRUE", chk = TRUE, id.name = "knn_scale")
  frm_knn <- rk.XML.frame(knn_k, knn_scale, label = "KNN Options", id.name = "frm_knn")

  cls_save_model <- rk.XML.saveobj("Save Model as", initial = "my_model", chk = TRUE, id.name = "cls_save_model")

  # Regla 11: Convertir la opción string del Radio button a Booleano para ocultar/mostrar el marco de KNN
  cond_is_knn <- rk.XML.convert(sources = list(cls_type), mode = c(equals = "knn"), id.name = "cond_is_knn")

  logic_cls <- rk.XML.logic(
    rk.XML.connect(governor = cls_data, get = "available", client = cls_vs, set = "root"),
    cond_is_knn,
    rk.XML.connect(governor = cond_is_knn, client = frm_knn, set = "visible")
  )

  dialog_cls <- rk.XML.dialog(
    rk.XML.row(
      cls_vs,
      rk.XML.col(cls_data, cls_dep, cls_indep, cls_type, frm_knn, cls_save_model)
    ), label = "Other Classifiers (KNN & Naive Bayes)"
  )

  js_calc_cls <- "
    var data = getValue('cls_data');
    var dep = parseVar(getValue('cls_dep'));
    var indep_raw = getValue('cls_indep');
    var algo = getValue('cls_type');
    var is_scale = getValue('knn_scale');

    var indep_str = '.';
    if (indep_raw !== '') {
        var indep_arr = indep_raw.split('\\n').map(parseVar).filter(Boolean);
        if (indep_arr.length > 0) { indep_str = indep_arr.map(function(v){ return '`' + v + '`'; }).join(' + '); }
    }
    var formula = '`' + dep + '` ~ ' + indep_str;

    if (algo === 'knn') {
        var k = getValue('knn_k');
        if (is_scale === 'TRUE') {
            echo('my_model <- caret::train(' + formula + ', data = ' + data + ', method = \"knn\", tuneGrid = data.frame(k = ' + k + '), preProcess = c(\"center\", \"scale\"))\\n');
        } else {
            echo('my_model <- caret::knn3(' + formula + ', data = ' + data + ', k = ' + k + ')\\n');
        }
    } else {
        echo('my_model <- e1071::naiveBayes(' + formula + ', data = ' + data + ')\\n');
    }
  "

 js_print_cls <- "
    var algo = getValue('cls_type');

    // CORRECCIÓN: Envolver los comandos de R dentro de echo()
    if (algo === 'knn') {
        echo('rk.header(\"K-Nearest Neighbors (KNN) Model\")\\n');
    } else {
        echo('rk.header(\"Naive Bayes Model\")\\n');
    }

    echo('rk.print(my_model)\\n');

    if (getValue('cls_save_model.active')) {
        echo('rk.print(paste0(\"<hr><b>Model saved as: </b><code>\", \"' + getValue('cls_save_model') + '\", \"</code>\"))\\n');
    }
  "

  comp_cls <- rk.plugin.component("Classifiers (KNN & Naive Bayes)", xml = list(dialog = dialog_cls, logic = logic_cls), js = list(require = c("caret", "e1071"), globals = js_helpers, calculate = js_calc_cls, printout = js_print_cls), hierarchy = h_mining)

  # =========================================================================================
  # 3B. COMPONENT: Model Evaluation (Confusion Matrix & ROC)
  # =========================================================================================
  eval_vs <- rk.XML.varselector(id.name = "eval_vs")
  eval_data <- rk.XML.varslot("Testing Dataset (e.g. data_test)", source = "eval_vs", classes = "data.frame", required = TRUE, id.name = "eval_data")
  eval_target <- rk.XML.varslot("Actual Target Variable in Test Data", source = "eval_vs", required = TRUE, id.name = "eval_target")

  eval_model <- rk.XML.input("Model Object Name (from Workspace)", initial = "tree_model", required = TRUE, id.name = "eval_model")

  eval_chk_cm <- rk.XML.cbox("Generate Confusion Matrix & Metrics (Accuracy, Sensitivity, etc.)", value = "TRUE", chk = TRUE, id.name = "eval_chk_cm")
  eval_chk_roc <- rk.XML.cbox("Generate ROC Curve and calculate AUC", value = "TRUE", chk = TRUE, id.name = "eval_chk_roc")

   eval_plot_w <- rk.XML.spinbox("ROC Plot Width (pixels)", min=100, max=2000, initial=800, real=FALSE, id.name="eval_plot_w")

  eval_plot_h <- rk.XML.spinbox("ROC Plot Height (pixels)", min=100, max=2000, initial=800, real=FALSE, id.name="eval_plot_h")

  frm_eval_plot <- rk.XML.frame(eval_plot_w, eval_plot_h, label = "ROC Plot Size")

  cond_roc <- rk.XML.convert(sources = list(eval_chk_roc), mode = c(equals = "TRUE"), id.name = "cond_roc")


  eval_preview <- rk.XML.preview(label = "Preview ROC Curve")

  logic_eval <- rk.XML.logic(
    rk.XML.connect(governor = eval_data, get = "available", client = eval_vs, set = "root"),
    cond_roc,
    rk.XML.connect(governor = cond_roc, client = frm_eval_plot, set = "visible")
  )

  dialog_eval <- rk.XML.dialog(
    rk.XML.row(
      eval_vs,
      rk.XML.col(
        eval_model, eval_data, eval_target,
        eval_chk_cm, eval_chk_roc, frm_eval_plot,
        eval_preview, # <-- Insertamos el botón aquí
        rk.XML.stretch()
      )
    ),
    label = "Model Evaluation (Metrics & ROC)"
  )

  js_calc_eval <- "
    var t_data = getValue('eval_data');
    var t_target = parseVar(getValue('eval_target'));
    var m_obj = getValue('eval_model');

    echo('test_df <- ' + t_data + '\\n');
    echo('actual_labels <- test_df[[\"' + t_target + '\"]]\\n');
    echo('if (!is.factor(actual_labels)) actual_labels <- as.factor(actual_labels)\\n\\n');

    echo('# Predict Classes\\n');
    echo('pred_class <- predict(' + m_obj + ', newdata = test_df, type = \"class\")\\n');
    echo('if (inherits(' + m_obj + ', \"train\")) pred_class <- predict(' + m_obj + ', newdata = test_df)\\n\\n'); // Fix for caret KNN

    if (getValue('eval_chk_cm') === 'TRUE') {
        echo('conf_mat <- caret::confusionMatrix(pred_class, actual_labels)\\n');
    }

    if (getValue('eval_chk_roc') === 'TRUE') {
        echo('# Predict Probabilities for ROC\\n');
        echo('if (inherits(' + m_obj + ', \"naiveBayes\")) {\\n');
        echo('  pred_prob <- predict(' + m_obj + ', newdata = test_df, type = \"raw\")\\n');
        echo('} else {\\n');
        echo('  pred_prob <- predict(' + m_obj + ', newdata = test_df, type = \"prob\")\\n');
        echo('}\\n');
        echo('# Take probabilities of the second class (assumed positive)\\n');
        echo('prob_pos <- pred_prob[, 2]\\n');
        echo('roc_obj <- pROC::roc(response = actual_labels, predictor = prob_pos, quiet = TRUE)\\n');
    }
  "

  js_print_eval <- "
    // 1. Apagamos los ejes automáticos de R (xaxt='n', yaxt='n')
    var plot_cmd = 'plot(roc_obj, col = \"#0055A4\", main = \"ROC Curve\", lwd = 2, print.auc = TRUE, legacy.axes = TRUE, xaxt = \"n\", yaxt = \"n\")';

    // 2. Dibujamos manualmente los ejes con números perfectos y redondeados
    var axes_cmd = 'axis(1, at = seq(0, 1, by = 0.2), labels = c(\"0.0\", \"0.2\", \"0.4\", \"0.6\", \"0.8\", \"1.0\"))\\n' +
                   'axis(2, at = seq(0, 1, by = 0.2), labels = c(\"0.0\", \"0.2\", \"0.4\", \"0.6\", \"0.8\", \"1.0\"))';

    // Lógica del PREVIEW (Live Preview)
    if (typeof is_preview !== 'undefined' && is_preview) {
        if (getValue('eval_chk_roc') === 'TRUE') {
            echo(plot_cmd + '\\n');
            echo(axes_cmd + '\\n');
        }
    }

    // Lógica de Salida Final (HTML)
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"Model Evaluation Results\")\\n');

        if (getValue('eval_chk_cm') === 'TRUE') {
            echo('rk.header(\"Confusion Matrix & Business Metrics\", level = 3)\\n');
            echo('rk.print(conf_mat$table)\\n');
            echo('rk.print(conf_mat$byClass)\\n');
            echo('rk.print(paste(\"<b>Overall Accuracy:</b>\", round(conf_mat$overall[\"Accuracy\"], 4)))\\n');
        }

        if (getValue('eval_chk_roc') === 'TRUE') {
            echo('rk.header(\"ROC Curve & AUC\", level = 3)\\n');
            echo('rk.print(paste(\"<b>Area Under Curve (AUC):</b>\", round(roc_obj$auc, 4)))\\n');

            echo('rk.graph.on(width = ' + getValue('eval_plot_w') + ', height = ' + getValue('eval_plot_h') + ')\\n');

            // Ejecutamos el gráfico y luego le agregamos los ejes hermosos
            echo(plot_cmd + '\\n');
            echo(axes_cmd + '\\n');

            echo('rk.graph.off()\\n');
        }
    }
  "

  comp_eval <- rk.plugin.component("Model Evaluation (ROC & CM)", xml = list(dialog = dialog_eval, logic = logic_eval), js = list(require = c("caret", "pROC"), globals = js_helpers, calculate = js_calc_eval, printout = js_print_eval), hierarchy = h_mining)

  # =========================================================================================
  # 4. BUILD SKELETON
  # =========================================================================================

  unlink("rk.business.mining", recursive = TRUE)

  # The Decision Tree is our Main Component
  rk.plugin.skeleton(
    about = about_info,
    path = ".",
    xml = list(dialog = dialog_tree, logic = logic_tree),
    js = list(require = c("rpart", "rpart.plot"), globals = js_helpers, calculate = js_calc_tree, printout = js_print_tree),
    components = list(comp_partition, comp_cls, comp_eval),
    pluginmap = list(name = "Decision Trees (Classification)", hierarchy = h_mining),
    dependencies = dependencies_node,
    create = c("pmap", "xml", "js", "desc", "rkh"),
    overwrite = TRUE,
    load = TRUE
  )
  })
