def login_code(initialLogin, standardLogin):
    n, m = len(initialLogin), len(standardLogin)
    i = j = 0
    sum1 = sum2 = 0
    count = 0

    while i < n or j < m:
        if sum1 == sum2 and sum1 != 0:
            count += 1
            sum1 = sum2 = 0

        if sum1 <= sum2 and i < n:
            sum1 += initialLogin[i]
            i += 1
        elif j < m:
            sum2 += standardLogin[j]
            j += 1
        else:
            return -1

    if sum1 == sum2:
        count += 1 if sum1 != 0 else 0
        return count
    else:
        return -1

print(login_code([1, 5, 6, 8, 2] ,[12, 8, 2]))  # Output: 2