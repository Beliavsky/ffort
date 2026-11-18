program p
implicit none
integer::a(2,2,2),b(2,2,2)
a=1
b=cshift(a,1)
print *, "PASS"
end program
