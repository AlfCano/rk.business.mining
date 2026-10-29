# rk.business.mining: Predictive Analytics and Classification for RKWard

![Version](https://img.shields.io/badge/Version-0.0.1-blue.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.business.mining/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.business.mining/actions/workflows/lintr.yml)
![AI Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=googlegemini&logoColor=white)

**A Zero-Code GUI Wrapper for Data Mining and Machine Learning bringing Business Analytics to RKWard**

`rk.business.mining` bridges the gap between complex machine learning algorithms and practical Business Analytics. Designed with modern data science workflows in mind (aligning with leading business analytics textbooks), this plugin provides a seamless, point-and-click interface to partition data, train Decision Trees, run K-NN or Naive Bayes classifiers, and evaluate business KPIs (like Accuracy, Sensitivity, and AUC via ROC curves)—all without writing a single line of R code.

---

## 🌟 Key Features

*   **Zero-Code Data Partitioning:** Easily split your datasets into Training and Testing subsets using stratified sampling (via `caret`) to maintain the exact proportion of your target variable.
*   **Stunning Decision Trees:** Build robust models with `rpart` and generate beautiful, highly customizable visualizations using `rpart.plot` (complete with business-friendly color palettes like Red-Yellow-Green).
*   **Industry-Standard Algorithms:** Quickly implement K-Nearest Neighbors (KNN) and Naive Bayes classifiers. Includes automatic data standardization/scaling for distance-based algorithms.
*   **Business KPIs at a Glance:** Automatically extract highly interpretable Confusion Matrices and business metrics (Accuracy, Sensitivity, Precision) to evaluate your models like a data scientist.
*   **Publication-Ready ROC Curves:** Generate ROC curves and calculate the Area Under the Curve (AUC) using the `pROC` engine. Features textbook-standard axes (1 - Specificity) and clean, scientific notation-free labels.
*   **Advanced Export Control:** Save your interactive models or plots back to the R workspace, or export graphics to disk (PNG, JPEG, PDF, SVG) with precise pixel dimensions and DPI resolution.
*   **Multilingual Ready:** Fully prepared for translation into English, Spanish, French, German, and Portuguese (Brazil).

---

## What's New in Version 0.0.1

*   **Initial Release:** Introduces a comprehensive, 4-step Machine Learning suite under RKWard's `Analysis > Predictive Analytics` menu.
*   **Intelligent UI Flow:** Utilizes dynamic gray-out effects and conditional logic to hide unnecessary parameters (e.g., automatically requesting the $k$ value and scaling options only when KNN is selected).
*   **Native GUI Integration:** Implements flawless HTML plot injection and safe saving mechanisms using RKWard's core graphical devices (`rk.graph.on`).

---

## ⚙️ Prerequisites

You must have [RKWard](https://rkward.kde.org/) installed along with the following R packages. The plugin will automatically attempt to load them when required:

```R
install.packages(c("rpart", "rpart.plot", "caret", "e1071", "pROC"))
```

---

## 🚀 Installation

You can install this plugin directly from GitHub using `remotes` or `devtools` inside your RKWard console:

```R
# Install the plugin
library("remotes")
install_github("AlfCano/rk.business.mining")
```

Once installed, restart RKWard to ensure the new menu entries and translations appear correctly.

---

## 🛠️ Usage Workflow

This plugin adds a comprehensive modeling suite under the **Analysis > Predictive Analytics** menu in RKWard:

### 1. Data Partitioning (Train / Test Split)
*The critical first step for any Predictive Analytics project.*
Securely split your dataset into training (e.g., 70%) and testing (e.g., 30%) sets using stratified sampling to ensure your target classes are well-represented in both sets.

### 2. Decision Trees (Classification)
*Highly interpretable models perfect for business presentations.*
Select your training data, target variable, and predictors. Tweak hyperparameters (Complexity Parameter, Max Depth), choose a beautiful color palette, and let the plugin generate the tree rules and visual nodes.

### 3. Other Classifiers (KNN & Naive Bayes)
*Alternative algorithms for benchmark comparisons.*
Train non-parametric models. The GUI intelligently reminds you to standardize your numeric data when selecting distance-based models like KNN.

### 4. Model Evaluation (Metrics & ROC)
*The Acid Test: Expose your models to the Testing Data.*
Pass your trained models and the untainted testing dataset to this tool. Generate comprehensive Confusion Matrices, extract KPIs, and plot pristine ROC Curves to evaluate the true predictive power (AUC) of your models.

---

## 📊 Real-World Case Study: Predicting Outcomes

To see the true power of `rk.business.mining` in a Business Analytics context (such as the methodologies taught in Jaggia's *Business Analytics* textbook), let's predict a categorical outcome. 

While textbooks often use customer churn or loan defaults, we will use a classic dataset pre-loaded in R: `kyphosis` (predicting whether a patient will develop a spinal deformity after surgery).

### Step 1: Load the Data & Partition
1. Open the **R Console** (bottom panel in RKWard) and run: `data(kyphosis, package="rpart")`
2. Go to the top menu: **Analysis > Predictive Analytics > Data Partitioning (Train/Test)**.
3. Select `kyphosis` as your Dataset and `Kyphosis` (the first column) as your Target.
4. Leave the training percentage at 70% and click **Submit**.
   *👉 You will see a clean summary indicating that `data_train` and `data_test` have been securely created in your workspace.*

### Step 2: Generate the Decision Tree (The Core Model)
1. Go to **Analysis > Predictive Analytics > Decision Trees (Classification)**.
2. Use `data_train` as your **Training Data**.
3. Select `Kyphosis` (the categorical absent/present variable) as the **Target Variable**.
4. *Leave the Predictors box blank* (this tells the algorithm to automatically use all remaining columns, just like in real-world data mining).
5. In the **Plot Options** tab, select the "Red-Yellow-Green (Business)" palette.
6. Click **Submit**.
   *👉 The plugin will output a beautiful tree plot and save the mathematical model as `tree_model`.*

### Step 3: Explore an Alternative Model (K-NN)
*Sometimes a director wants to compare scenarios. What if we measure "distances" between patients using K-NN instead of logical rules?*
1. Go to **Analysis > Predictive Analytics > Other Classifiers (KNN & Naive Bayes)**.
2. **Training Data:** Select `data_train`.
3. **Target Variable:** Select `Kyphosis`. (Leave Predictors blank).
4. **Classifier Algorithm:** Select "K-Nearest Neighbors (KNN)".
5. Leave **"Standardize (Scale) numeric data?"** checked (Vital for K-NN because age and number of vertebrae are measured on completely different scales!).
6. **Save Model as:** Change it to `knn_model` (so we don't overwrite our tree).
7. Click **Submit**.

### Step 4: The Acid Test (Model Evaluation)
*Here we test our brand-new models using the test data we sliced off at the beginning—data the algorithm **has never seen before**.*
1. Go to **Analysis > Predictive Analytics > Model Evaluation (Metrics & ROC)**.
2. **Model Object Name:** Type `tree_model` (the one we saved in Step 2).
3. **Testing Dataset:** Select `data_test` (the pure, untainted database).
4. **Actual Target Variable:** Choose `Kyphosis` (ensure you select it from the columns of `data_test`).
5. Ensure the **Confusion Matrix** and **ROC Curve** checkboxes are selected.
6. Click **Submit**.

---

## 🗣️ Communicating with Numbers (Translating Output to Business)

True to the Jaggia philosophy, we don't hand management a report full of "p-values" and raw R code. We use the tables generated by RKWard to speak in terms of operations and profitability.

Here is how you "pitch" the clean HTML reports RKWard just gave you:

**1. Interpreting the Confusion Matrix & Accuracy:**
Look at the *Business Metrics* section. If the *Overall Accuracy* is 79%, you tell the Medical Director (or CEO):
> *"Out of every 100 surgeries (or customers), our model correctly predicts the outcome for 79 of them. This allows us to surgically target our preventive resources and budget rather than guessing."*

**2. Interpreting Sensitivity (True Positive Rate):**
Look at the *Sensitivity* row.
> *"The model successfully flagged the vast majority of patients who were actually at risk. While our sensitivity indicates we didn't catch every single one, we will still be able to cut post-operative complications by more than half."*

**3. Interpreting the ROC Curve (AUC):**
Look at the generated ROC plot and the Area Under the Curve (AUC) number.
> *"Our model has an AUC of **0.75**. Considering that flipping a coin gives us 0.50, our system has real predictive power. With this, the hospital can confidently decide to allocate preventive physical therapy specifically to patients who fall into the 'red node' of our decision tree, optimizing the budget."*

---

## 🌍 Internationalization (i18n)

The graphical interface automatically adapts to your RKWard language settings. Currently supported languages:
*   🇺🇸 English (Default)
*   🇪🇸 Spanish (Español)
*   🇫🇷 French (Français)
*   🇩🇪 German (Deutsch)
*   🇧🇷 Portuguese (Português do Brasil)

---

## 📝 License and Author

**Author:** Alfonso Cano ([@AlfCano](https://github.com/AlfCano))  
**Email:** alfonso.cano@correo.buap.mx  
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)

This project is licensed under the **GPL (>= 3)** License.
