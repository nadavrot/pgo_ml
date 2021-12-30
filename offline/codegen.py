# A code generator for the decision tree state machine.

class Node:
    """ Represents a node in a temporary in-memory decision tree
        We mainly use this data structure to assign a good node
        ordering that optimizes cache access patterns. """
    def __init__(self, feature, cond_val, left, right):
        self.cond_val = cond_val # or return value
        self.feature = feature # or -1 for done
        self.left = left
        self.rigt = right
        self.idx = None

    def set_index(self, start_idx):
        """ Assign indices to all nodes in the tree in a way
            that optimzies cache access patterns. """
        self.idx = start_idx
        start_idx = start_idx + 1
        if (self.left):
            start_idx = self.left.set_index(start_idx)
            start_idx = self.right.set_index(start_idx)
        return start_idx

    def add_children(self, left, right):
        self.left = left
        self.right = right

    @staticmethod
    def new_leaf(value): return Node(-1, value, None, None)

    @staticmethod
    def new_node(feature, cond_val): return Node(feature, cond_val, None, None)

    def write(self, states):
        states.grow(self.idx)
        if (self.left == None):
            states.add_leaf(self.idx, self.cond_val)
            return
        states.add_cond(self.idx, self.feature, self.cond_val, self.left.idx, self.right.idx)
        self.left.write(states)
        self.right.write(states)

class States:
    """ Represents a state machine. We use this data structure to flatten the
        Tree (of the Node data structure that is defined above). """
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
int next_step(float *dest,
              int *state,
              const float *input,
              const short *FE,
              const float *C,
              const short *L,
              const short *R,
              unsigned num_states) {
    // We are already done.
    if (*state == -1) return 0;
    // Save output and exit.
    if (FE[*state] == -1) { *dest += C[*state]; *state = -1; return 0; }
    // do one step.
    int ff = FE[*state];
    if (input[ff] < C[*state]) { *state = L[*state]; } else { *state = R[*state]; }
    // Need another step.
    return 1;
}
""" 

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

def generate_node_tree(node):
    """ Returns Node Tree """
    if ("leaf" in node):
        return Node.new_leaf(node["leaf"])

    feature_name = node["split"]
    assert(feature_name[0] == "f")
    feature_num= feature_name[1:]
    cond_val = node["split_condition"]
    yes = node["yes"]
    no = node["no"]

    new_node = Node.new_node(feature_num, cond_val)

    children = node["children"]
    assert(children[0]["nodeid"] == yes)
    assert(children[1]["nodeid"] == no)
    left = generate_node_tree(children[0])
    right = generate_node_tree(children[1])
    new_node.left = left
    new_node.right = right
    return new_node

def generate_func_for_tree(jtree, name, idx):
    states = States()
    n = generate_node_tree(jtree)
    n.set_index(0)
    n.write(states)
    states.trim()
    sb = ""
    sb += states.dump(name)
    sb += "void %s(float *dest, int *state, const float *input, int *need_more) {\n" % name
    sb += ""
    sb += "  if (next_step(dest, state, input, FE_%s, C_%s, L_%s, R_%s, %d)) {*need_more = 1;}\n" % (name, name, name, name, states.size())
    sb += "\n}\n"
    return sb

def generate_code_for_forest(jtrees, num_classes, num_features, message):
    decl = "// " + message + "\n"
    decl += States.get_interpreter(num_features)
    sb = "// Return the label or -1 for low confidence.\n"
    sb += "int predict(const float *features, unsigned num_features) {\n"
    sb += "  if (num_features != %d) abort();\n" % (num_features)
    sb += "  int need_more = 0;\n"
    sb += "  int states[%d] = {0,};\n" % (len(jtrees))
    sb += "  float bins[%d] = {0.,};\n" % (num_classes)
    sb += "  while (1) {\n    need_more = 0;\n"
    for idx, tree in enumerate(jtrees):
        name = "pred_" + str(idx)
        sb += "    " + name + "(&bins[%d], &states[%d], " % (idx % num_classes, idx) + "features, &need_more);\n"
        decl += generate_func_for_tree(tree, name, idx)

    sb += "    if (need_more == 0) {break;}\n  }\n"
    sb += "  int best = 0;\n"
    sb += "  for (int i = 0; i < %d; i++) " % num_classes
    sb += "  { if (bins[i] > bins[best]) best = i; }\n"
    sb += "  if (bins[best] < 0.5) return -1.0;\n"
    sb += "  return best;\n"
    sb += "}\n"
    return decl + sb

# Generate a unit test for the generated code.
def gen_test(X_test, y_pred, num_features):
    sb = "int main() {\n"
    for i in range(20):
        res = ",".join(map(str, X_test[i]))
        sb += "  float A%d[] = { %s };\n" %(i, res)
        sb += "  printf(\"result = %%d vs %f\\n\", predict(A%d, %d));\n" % (y_pred[i], i, num_features)

    sb += "  printf(\"Evaluating 1,000,000 inputs.\\n\");\n"
    sb += "  float sum = 0;\n"
    sb += "  for (int i = 0; i < 1000*1000; i++) {\n"
    sb += "    A0[0] = (i % 10);\n"
    sb += "    sum += predict(A0, %d);\n" % (num_features)
    sb += "  }"
    sb += "  printf(\"Result = %f.\\n\", sum);\n"
    sb += "}"
    return sb

