program p
implicit none
integer::n
logical::m(3)
n=2
m=.true.
print *,merge([1,2,3],0,m(:n))
end program
