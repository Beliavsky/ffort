program p
implicit none
integer::a(3),b(3)
b=cshift(a,1)
print *, "PASS"
end program
