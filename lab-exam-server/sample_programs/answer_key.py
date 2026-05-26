# ============================================================
# Answer Key — 10 Sample Lab Exam Questions
# Use these solutions to verify all test cases pass.
# ============================================================

# Q1: Sum of Two Numbers
def q1():
    a = int(input())
    b = int(input())
    print(a + b)

# Q2: Factorial of a Number
def q2():
    n = int(input())
    result = 1
    for i in range(2, n + 1):
        result *= i
    print(result)

# Q3: Check Prime Number
def q3():
    n = int(input())
    if n < 2:
        print("Not Prime")
    else:
        for i in range(2, int(n**0.5) + 1):
            if n % i == 0:
                print("Not Prime")
                return
        print("Prime")

# Q4: Fibonacci Sequence
def q4():
    n = int(input())
    a, b = 0, 1
    result = []
    for _ in range(n):
        result.append(a)
        a, b = b, a + b
    print(*result)

# Q5: Reverse a String
def q5():
    s = input()
    print(s[::-1])

# Q6: Count Vowels in a String
def q6():
    s = input()
    print(sum(1 for c in s if c.lower() in 'aeiou'))

# Q7: Palindrome Check
def q7():
    s = input()
    print("Yes" if s == s[::-1] else "No")

# Q8: Largest Element in a List
def q8():
    n = int(input())
    nums = list(map(int, input().split()))
    print(max(nums))

# Q9: Sum of Digits
def q9():
    n = input()
    print(sum(int(d) for d in n))

# Q10: Simple Calculator
def q10():
    a = float(input())
    b = float(input())
    op = input().strip()
    if op == '+':
        print(f"{a + b:.2f}")
    elif op == '-':
        print(f"{a - b:.2f}")
    elif op == '*':
        print(f"{a * b:.2f}")
    elif op == '/':
        if b == 0:
            print("Error: Division by zero")
        else:
            print(f"{a / b:.2f}")
