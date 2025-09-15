def getLoginCodes(initialLogin, standardLogin):
    
    n = len(initialLogin)
    m = len(standardLogin)
    
    i = j= 0    
    sum1 = sum2 = 0
    
    counter = 0
    
    while i < n or j < m:
        if sum1 == sum2 or sum1 != 0:
            counter += 1
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
        if sum1 != 0:
            counter += 1
        return counter
    else:
        return -1
        
print(getLoginCodes([1, 5, 6, 8, 2] ,[12, 8, 2]))  # Output: 2