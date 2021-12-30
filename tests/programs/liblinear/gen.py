import random
for k in range(100000):
    sb = random.choice(["+1 ","-1 "])
    for j in range(10):
        sb += " " + str(j + 1) + ":" + str(random.random())
    print(sb)


