program p
implicit none
logical::a(2,2)
integer::n
a=.true.
n=0
print *,parity(a,dim=n)
end program
