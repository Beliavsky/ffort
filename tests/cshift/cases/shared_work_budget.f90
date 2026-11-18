program p
implicit none
integer::a(1000),b(1000)
a=1
b=cshift(a,1)
print *, "PASS"
end program
