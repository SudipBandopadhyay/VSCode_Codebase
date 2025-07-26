def factorial(num):
    factorial = num
    while num >1:
        factorial = factorial * (num - 1)
        num -= 1
    return factorial

def main():
    num=input("Enter number:")
    print(num)
    print(factorial(int(num)))    
    print('Success')


if __name__ == "__main__":
    main()
