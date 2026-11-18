program p
implicit none
integer::a(3)
a=cshift(array=[1,2,3],1)
print *, "PASS"
end program
