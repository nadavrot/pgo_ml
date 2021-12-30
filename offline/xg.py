#!/usr/bin/python
from numpy import loadtxt
from xgboost import XGBClassifier, XGBRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from os.path import exists
from collections import Counter
import argparse
import json
import numpy as np
from codegen import *

parser = argparse.ArgumentParser(description='Train and save to C.')
parser.add_argument('model', nargs='?', type=str,
                    help='files to process')
parser.add_argument('-o', '--out',
                    default='out.c',
                    dest='out',
                    help='Location of the saved c file',
                    type=str)
parser.add_argument('-m', '--message',
                    default='',
                    dest='message',
                    help='A message to embed in the generated file',
                    type=str)
parser.add_argument('--test', default=False, action='store_true')
parser.add_argument('--importance', default=False, action='store_true')
args = parser.parse_args()

if not exists(args.model):
    print("Model file " + args.model + " does not exist")
    exit(0)

# Prints a histogram of the errors.
def ascii_histogram(seq, msg) -> None:
    print(msg)
    counted = Counter(seq)
    total = sum([counted[k] for k in sorted(counted)])
    for k in sorted(counted):
        stars = (100 * counted[k]) / total
        print('{0} {1}'.format(int(k), '+' * int(stars)))

# Load and normalize the data.
dataset = loadtxt(args.model, delimiter=",")
# split data into X and y
X = dataset[:,1:]
Y = dataset[:,0]

Y= np.where(Y <= 8, 0, Y)
Y= np.where(Y > 92, 2, Y)
Y= np.where(Y > 8, 1, Y)

print("Loaded %d rows." % len(X))
num_features = len(X[0])

# Split data into train and test sets.
seed = 7
test_size = 0.1
X_train, X_test, y_train, y_test = train_test_split(X, Y, test_size=test_size, random_state=seed)

ascii_histogram(y_train, "Input labels:")

# Classify the data into the different classes.
print("Training.")
model = XGBClassifier(use_label_encoder=False, eval_metric='mlogloss', objective = "multi:softprob", n_estimators = 9, max_depth = 14, num_class = 3)
model.fit(X_train, y_train)

print("Testing.")

# Make predictions for test data.
y_pred = model.predict(X_test)
predictions = [round(value) for value in y_pred]

# Check the accuracy of the model.
accuracy = accuracy_score(y_test, predictions)
print("Accuracy: %.2f%%" % (accuracy * 100.0))

accuracy = np.abs((y_test - predictions))
ascii_histogram(accuracy, "Errors:")

# Generate the C code for the learned trees.
model_dump = model.get_booster().get_dump(dump_format="json")
trees = [json.loads(d) for d in model_dump]
num_classes = model.n_classes_
sb = generate_code_for_forest(trees, num_classes, num_features, args.message)

if (args.test):
    sb += gen_test(X_test, y_pred, num_features)

print("Writing to " + args.out)
f = open(args.out, "w")
f.write(sb)
f.close()

# Test the importance of individual features.
if (args.importance):
    print("Testing importance of features")
    feature_error = [0 for _ in range(len(X[0]))]
    for feature_idx in range(len(feature_error)):
        for row in X_train[0:100]:
            inp = row
            y1 = model.predict([inp])
            inp[feature_idx] += 1.
            y2 = model.predict([inp])
            if (y1 != y2):
                feature_error[feature_idx] += 1
    print(feature_error)

