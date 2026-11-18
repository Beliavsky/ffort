program p
implicit none
logical::a(2,3),b(3)
a=.true.
a(1,2)=.false.
b=parity(a,dim=1)
print *,b
end program
