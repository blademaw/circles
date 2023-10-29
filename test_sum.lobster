def my_fold(xs, init, fun):
    for (xs): init = fun(init, _)
    return init

def my_sum(a, b):
    return a + b

print(my_fold([1,2,3], 0) a, b: a + b) // this works
print(my_fold([1,2,3], 0, my_sum))     // this doesn't
