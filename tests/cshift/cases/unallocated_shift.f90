program p
implicit none
integer,allocatable::s(:)
integer::a(2,3),b(2,3)
a=1
b=cshift(a,s)
print *, "PASS"
end program
