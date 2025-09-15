
#!/bin/python3

import math
import os
import random
import re
import sys



#
# Complete the 'getExpressionSums' function below.
#
# The function is expected to return an INTEGER.
# The function accepts STRING num as parameter.
#

#!/bin/python3

import math
import os
import random
import re
import sys



#
# Complete the 'getExpressionSums' function below.
#
# The function is expected to return an INTEGER.
# The function accepts STRING num as parameter.
#

def getExpressionSums(num):
    # Write your code here
    MOD = 10**9 + 7
    n = len(num)

    total = 0
    # There are 2^(n-1) ways to insert '+'
    for mask in range(1 << (n - 1)):
        parts = []
        last = 0
        for i in range(n - 1):
            if mask & (1 << i):
                parts.append(int(num[last:i+1]))
                last = i + 1
        parts.append(int(num[last:]))

        total = (total + sum(parts)) % MOD

    return total



print(getExpressionSums('100'))