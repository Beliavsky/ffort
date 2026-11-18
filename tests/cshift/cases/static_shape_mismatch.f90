program p
implicit none
integer::a(2,3)
a=1
a=cshift(a,[1,2])
print *, "PASS"
end program
