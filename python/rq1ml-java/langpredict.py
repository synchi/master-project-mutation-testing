import pandas as pd
import numpy as np

import os
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

from time import sleep


projname = sys.argv[1]

# Get var name as String
def retrieve_name(var):
    for fi in reversed(inspect.stack()):
        names = [var_name for var_name, var_val in fi.frame.f_locals.items() if var_val is var]
        if len(names) > 0:
            return names[0]

# print("Loading data...")

# Load head for cols
A_X  = pd.read_csv("langhead.csv")
A_X.insert(0, 'PredictionIdx', 0)


features_ready = False
print("Predictor waiting for features...")
while(features_ready == False):
    try:
    #  with open( "a.txt" ) as f :
    #      print(f.readlines())
        B = pd.read_csv("/scratch/predictionfiles/features.csv")
        features_ready = True
        print("Features received")
    except Exception:
        sleep(0.25)


# print("CSV data loaded")


# Set up project to predict
B_X = B
B_X.drop(labels="Detected", axis=1, inplace=True)
B_X = pd.get_dummies(B_X, columns=["MutOperator","ReturnType"])

# Find and add any missing columns
missing_cols = set( A_X.columns ) - set( B_X.columns )
for c in missing_cols:
    B_X[c] = 0
# Ensure the order of column in the test set is in the same order than in train set
B_X = B_X[A_X.columns]

ids = B_X["PredictionIdx"]
B_X.drop(labels="PredictionIdx", axis=1, inplace=True)

# Load classifier
clf = joblib.load("/home/saraoonk/rq1ml-java/output/java-scores/" + projname + '_model.pkl')
preds = clf.predict(B_X)


# print("Classifier ready. Performing predictions...")

# Perform predictions on B
B_pred = clf.predict(B_X)
result = pd.concat([ids, pd.DataFrame(B_pred)], axis=1)

result.to_csv(r'/scratch/predictionfiles/temp_predictions.csv', index=False, header=False)

os.rename('/scratch/predictionfiles/temp_predictions.csv', '/scratch/predictionfiles/predictions.csv')

