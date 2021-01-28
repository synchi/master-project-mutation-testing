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

print("Loading data...")

# Load data
carbon    = pd.read_csv("ml-features/carbon.csv")
email     = pd.read_csv("ml-features/email.csv")
guzzle    = pd.read_csv("ml-features/guzzle.csv")
jwt       = pd.read_csv("ml-features/jwt.csv")
koel      = pd.read_csv("ml-features/koel.csv")
larah     = pd.read_csv("ml-features/larah.csv")
larap     = pd.read_csv("ml-features/larap.csv")
parsedown = pd.read_csv("ml-features/parsedown.csv")
csfix     = pd.read_csv("ml-features/csfix.csv")
phpdotenv = pd.read_csv("ml-features/phpdotenv.csv")
psysh     = pd.read_csv("ml-features/psysh.csv")
uuid      = pd.read_csv("ml-features/uuid.csv")
slim      = pd.read_csv("ml-features/slim.csv")
wechat    = pd.read_csv("ml-features/wechat.csv")
whoops    = pd.read_csv("ml-features/whoops.csv")

print("CSV data loaded")

# Projects for training
A = [
    carbon,
    email,
    # guzzle,
    jwt,
    koel,
    larah,
    larap,
    parsedown,
    csfix,
    phpdotenv,
    psysh,
    uuid,
    slim,
    wechat,
    whoops,
]

# Current project to predict
# B = carbon
# B = email
B = guzzle
# B = jwt
# B = koel
# B = larah
# B = larap
# B = parsedown
# B = csfix
# B = phpdotenv
# B = psysh
# B = uuid
# B = slim
# B = wechat
# B = whoops

# Total number of samples
totalSize = 0
for project in A: 
    totalSize += len(project)

# Add weights per project
for project in A:
    projectSize = len(project)
    weight = totalSize / projectSize
    project["Weight"] = [weight] * projectSize     

print("Weights added")

# Merge projects into training data
A_X = pd.concat(A)
A_X = A_X.sample(frac=1)

# Remove irrelevant column
A_X.drop(labels="Location", axis=1, inplace=True)

print("Training projects merged and shuffled")

# Separate the target
A_y = A_X["Detected"]
A_X.drop(labels="Detected", axis=1, inplace=True)

# Convert labels to numbers
A_X = pd.get_dummies(A_X, columns=["MutOperator","NodeType","StmtType","ReturnType"])

print("Training data processed") 

# Set up project to predict
B_X = B
B_y = B_X["Detected"]
B_X.drop(labels="Detected", axis=1, inplace=True)
B_X = pd.get_dummies(B_X, columns=["MutOperator","NodeType","StmtType","ReturnType"])

# Find and add any missing columns
missing_cols = set( A_X.columns ) - set( B_X.columns )
for c in missing_cols:
    B_X[c] = 0
# Ensure the order of column in the test set is in the same order than in train set
B_X = B_X[A_X.columns]

print("Subject prepared for prediction. Training classifier...")

# Set up classifier using A projects
gb_clf = GradientBoostingClassifier(n_estimators=6, learning_rate=0.75, max_features=50, max_depth=6, random_state=1, verbose=0)
gb_clf.fit(A_X, A_y)

print("Classifier ready. Performing predictions...")

# Perform predictions on B
B_pred = gb_clf.predict(B_X)

print("Complete! Results: \n")

# Evaluate
prec = precision_score(y_true=B_y, y_pred=B_pred, average='binary')
rec = recall_score(y_true=B_y, y_pred=B_pred, average='binary')

p, r, _ = precision_recall_curve(B_y, B_pred, pos_label=1)
aucval = auc(r, p)

fm = 2 * (prec * rec) / (prec + rec)

acc = accuracy_score(y_true=B_y, y_pred=B_pred, normalize=True)


modelName = retrieve_name(B) + "_model.pkl"

print("\n")
print(modelName)
print("PREC: ", prec)
print("REC: ", rec)
print("AUC: ", aucval)
print("F1: ", fm)
print("ACC: ", acc)

# Save the model
with open(modelName, 'wb') as f:
    pickle.dump(gb_clf, f)

print("\n \nModel saved as " + modelName)



