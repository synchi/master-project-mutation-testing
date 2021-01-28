import pandas as pd
import numpy as np

import sys
import pickle 
import joblib
import inspect

from random import shuffle

from sklearn.preprocessing import MinMaxScaler

from sklearn.ensemble import GradientBoostingClassifier

from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import precision_recall_curve
from sklearn.metrics import auc

# Get var name as String
def retrieve_name(var):
    for fi in reversed(inspect.stack()):
        names = [var_name for var_name, var_val in fi.frame.f_locals.items() if var_val is var]
        if len(names) > 0:
            return names[0]

# print("Loading data...")

# Load data
assertj  = pd.read_csv("ml-features/java/6836325_assertj-core_ml-extract_2020-11-13_01-23-03_output.csv")
cli      = pd.read_csv("ml-features/java/6836326_commons-cli_ml-extract_2020-11-13_01-22-23_output.csv")
csv      = pd.read_csv("ml-features/java/6836328_commons-csv_ml-extract_2020-11-13_01-23-28_output.csv")
functor  = pd.read_csv("ml-features/java/6836329_commons-functor_ml-extract_2020-11-13_01-24-23_output.csv")
hikari   = pd.read_csv("ml-features/java/6836330_HikariCP_ml-extract_2020-11-13_01-39-26_output.csv")
io       = pd.read_csv("ml-features/java/6836331_commons-io_ml-extract_2020-11-13_01-42-27_output.csv")
jopt     = pd.read_csv("ml-features/java/6836332_jopt-simple_ml-extract_2020-11-13_01-43-32_output.csv")
mime4j   = pd.read_csv("ml-features/java/6836335_james-mime4j_ml-extract_2020-11-13_02-00-50_output.csv")
retrofit = pd.read_csv("ml-features/java/6836336_retrofit_ml-extract_2020-11-13_02-01-49_output.csv")
text     = pd.read_csv("ml-features/java/6836337_commons-text_ml-extract_2020-11-13_02-26-54_output.csv")
wire     = pd.read_csv("ml-features/java/6836338_wire_ml-extract_2020-11-13_02-57-38_output.csv")
codec    = pd.read_csv("ml-features/java/6836384_commons-codec_ml-extract_2020-11-13_04-17-21_output.csv")
lang     = pd.read_csv("ml-features/java/6836385_commons-lang_ml-extract_2020-11-13_04-57-07_output.csv")
math     = pd.read_csv("ml-features/java/6836334_commons-math_ml-extract_2020-11-13_01-51-06_output.csv")

# print("CSV data loaded")

# Projects for training
A = [
    assertj,
    cli,
    csv,
    functor,
    hikari,
    io,
    # jopt,
    mime4j,
    retrofit,
    text,
    wire,
    codec,
    lang,
    math,
]

# Current project to predict
B = jopt

# Total number of samples
totalSize = 0
for project in A: 
    totalSize += len(project)

# Add weights per project
for project in A:
    projectSize = len(project)
    weight = totalSize / projectSize
    project["Weight"] = [weight] * projectSize     

# print("Weights added")

# Merge projects into training data
A_X = pd.concat(A)
A_X = A_X.sample(frac=1)

# print("Training projects merged and shuffled")

# Separate the target
A_y = A_X["Detected"]
A_X.drop(labels="Detected", axis=1, inplace=True)

# Convert labels to numbers
A_X = pd.get_dummies(A_X, columns=["MutOperator","ReturnType"])

# print("Training data processed") 

# Set up project to predict
B_X = B
B_y = B_X["Detected"]
B_X.drop(labels="Detected", axis=1, inplace=True)
B_X = pd.get_dummies(B_X, columns=["MutOperator","ReturnType"])

# Find and add any missing columns
missing_cols = set( A_X.columns ) - set( B_X.columns )
for c in missing_cols:
    B_X[c] = 0
# Ensure the order of column in the test set is in the same order than in train set
B_X = B_X[A_X.columns]

# print("Subject prepared for prediction. Training classifier...")

# Set up classifier using A projects
gb_clf = GradientBoostingClassifier(n_estimators=250, learning_rate=0.75, max_features=50, max_depth=6, random_state=1, verbose=0)
gb_clf.fit(A_X, A_y)

# print("Classifier ready. Performing predictions...")

# Perform predictions on B
B_pred = gb_clf.predict(B_X)

# print("Complete! Results: \n")

# Evaluate
prec = precision_score(y_true=B_y, y_pred=B_pred, average='binary')
rec = recall_score(y_true=B_y, y_pred=B_pred, average='binary')

p, r, _ = precision_recall_curve(B_y, B_pred, pos_label=1)
aucval = auc(r, p)

fm = 2 * (prec * rec) / (prec + rec)

print("PREC: ", prec)
print("REC: ", rec)
print("AUC: ", aucval)
print("F1: ", fm)

# Save the model
modelName = retrieve_name(B) + "_model.pkl"
with open(modelName, 'wb') as f:
    pickle.dump(gb_clf, f)

# print("\n \nModel saved as " + modelName)


