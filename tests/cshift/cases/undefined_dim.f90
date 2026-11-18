program p
implicit none
integer::a(3),b(3),d
a=1
b=cshift(a,1,d)
print *, "PASS"
end program
