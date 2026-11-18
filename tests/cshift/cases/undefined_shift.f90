program p
implicit none
integer::a(3),b(3),s
a=1
b=cshift(a,s)
print *, "PASS"
end program
