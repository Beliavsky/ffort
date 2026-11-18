program p
implicit none
integer::a(2,2),s(2,2)
a=1
s=0
a=cshift(a,s)
print *, "PASS"
end program
