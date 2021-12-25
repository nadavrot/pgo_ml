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

# Load and normalize the data.
dataset = loadtxt(args.model, delimiter=",")
# split data into X and y
X = dataset[:,1:]
Y = dataset[:,0]
Y = Y.round(-1)

Y= np.where(Y <= 5, 0, Y)
Y= np.where(Y > 95, 2, Y)
Y= np.where(Y > 5, 1, Y)

print("Loaded %d rows." % len(X))
num_features = len(X[0])

# Split data into train and test sets.
seed = 7
test_size = 0.1
X_train, X_test, y_train, y_test = train_test_split(X, Y, test_size=test_size, random_state=seed)

# Classify the data into the different classes.
print("Training.")
model = XGBClassifier(use_label_encoder=False, eval_metric='mlogloss', objective = "multi:softprob", n_estimators = 9, max_depth = 14, num_class = 3)
model.fit(X_train, y_train)

# Make predictions for test data.
y_pred = model.predict(X_test)
predictions = [round(value) for value in y_pred]

# Check the accuracy of the model.
accuracy = accuracy_score(y_test, predictions)
print("Accuracy: %.2f%%" % (accuracy * 100.0))

# Prints a histogram of the errors.
def ascii_histogram(seq) -> None:
    print("Histogram of errors:")
    counted = Counter(seq)
    total = sum([counted[k] for k in sorted(counted)])
    for k in sorted(counted):
        stars = (100 * counted[k]) / total
        print('{0} {1}'.format(int(k), '+' * int(stars)))

accuracy = np.abs((y_test - predictions))
ascii_histogram(accuracy)

# Code generator for the state machine.
class States:
    def __init__(self):
        self.feature = [] # or -1 for done
        self.cond_val = [] # or outcome
        self.left = []
        self.right = []

    def size(self): return len(self.feature)

    def grow(self, idx):
        while(self.size() < idx + 1):
            self.feature.append(-1)
            self.cond_val.append(0.)
            self.left.append(-1)
            self.right.append(-1)

    def trim(self):
        while (self.left[-1] == -1): self.left.pop()
        while (self.right[-1] == -1): self.right.pop()

    def add_cond(self, idx, feature, cond_val, left, right):
        self.grow(idx)
        self.feature[idx] = feature
        self.cond_val[idx] = cond_val
        self.left[idx] = left
        self.right[idx] = right

    def add_leaf(self, idx, outcome):
        self.grow(idx)
        self.feature[idx] = -1
        self.cond_val[idx] = outcome
        self.left[idx] = -1
        self.right[idx] = -1

    @staticmethod
    def get_interpreter(num_features):
        return """
float interpret(const float *input,
                const short *FE,
                const float *C,
                const short *L,
                const short *R, unsigned num_states) {
  int state = 0;
  while (1) {
    if (state > (int)num_states) abort();
    if (FE[state] == -1) return C[state];
    int ff = FE[state];
    if (ff > %d) abort();
    if (input[ff] < C[state]) { state = L[state]; } else { state = R[state]; }
  }
}
""" % (num_features)

    def dump(self, suffix):
        sb = ""
        sb += "const short FE_%s[%d] = {" % (suffix, self.size())
        sb += ",".join(map(str, self.feature)) + "};\n"
        sb += "const float C_%s[%d] = {" % (suffix, self.size())
        sb += ",".join(map(str, self.cond_val)) + "};\n"
        sb += "const short L_%s[%d] = {" % (suffix, len(self.left))
        sb += ",".join(map(str, self.left)) + "};\n"
        sb += "const short R_%s[%d] = {" % (suffix, len(self.right))
        sb += ",".join(map(str, self.right)) + "};\n"
        return sb

def visit_node(states, node):
    idx = int(node["nodeid"])
    if ("leaf" in node):
        states.add_leaf(idx, node["leaf"])
        return

    feature_name = node["split"]
    assert(feature_name[0] == "f")
    feature_num= feature_name[1:]
    cond_val = node["split_condition"]
    yes = node["yes"]
    no = node["no"]
    states.add_cond(idx, feature_num, cond_val, yes, no)
    for ch in node["children"]:
        visit_node(states, ch)

def generate_func_for_tree(jtree, name):
    states = States()
    visit_node(states, jtree)
    states.trim()
    sb = ""
    sb += states.dump(name)
    sb += "float %s(const float *input) {\n" % name
    sb += " return interpret(input, FE_%s, C_%s, L_%s, R_%s, %d);" % (name, name, name, name, states.size())
    sb += "\n}\n"
    return sb

def generate_code_for_forest(jtrees, num_classes, num_features, message):
    decl = "// " + message + "\n"
    decl += "// " + args.model + "\n"
    decl += States.get_interpreter(num_features)
    sb = "// Return the label or -1 for low confidence.\n"
    sb += "int predict(const float *features, unsigned num_features) {\n"
    sb += "  if (num_features != %d) abort();\n" % (num_features)
    sb += "  float bins[%d] = {0.,};\n" % (num_classes)
    for idx, tree in enumerate(jtrees):
        name = "pred_" + str(idx)
        sb += "  bins[%d] += " % (idx % num_classes) + name + "(features);\n"
        decl += generate_func_for_tree(tree, name)
    sb += "  int best = 0;\n"
    sb += "  for (int i = 0; i < %d; i++) " % num_classes
    sb += "  { if (bins[i] > bins[best]) best = i; }\n"
    sb += "  if (bins[best] < 0.5) return -1.0;\n"
    sb += "  return best;\n"
    sb += "}\n"
    return decl + sb


# Generate the C code for the learned trees.
model_dump = model.get_booster().get_dump(dump_format="json")
trees = [json.loads(d) for d in model_dump]
num_classes = model.n_classes_
sb = generate_code_for_forest(trees, num_classes, num_features, args.message)

# Generate a unit test for the generated code.
def gen_test():
    sb = "int main() {\n"
    for i in range(10):
        res = ",".join(map(str, X_test[i]))
        sb += "  float A%d[] = { %s };\n" %(i, res)
        sb += "  printf(\"result = %%f vs %f\\n\", predict(A%d, %d));\n" % (y_pred[i], i, num_features)

    sb += "  printf(\"Evaluating 1,000,000 inputs.\\n\");\n"
    sb += "  float sum = 0;\n"
    sb += "  for (int i = 0; i < 1000*1000; i++) {\n"
    sb += "    A0[0] = (i % 10);\n"
    sb += "    sum += predict(A0, %d);\n" % (num_features)
    sb += "  }"
    sb += "  printf(\"Result = %f.\\n\", sum);\n"
    sb += "}"
    return sb

if (args.test):
    sb += gen_test()

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

