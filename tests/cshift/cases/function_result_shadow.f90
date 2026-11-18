program p
implicit none
integer::a(3)
a=make()
if(any(a/=[4,5,6])) error stop 1
print *, "PASS"
contains
function make() result(cshift)
integer::cshift(3)
cshift=[4,5,6]
cshift(2)=5
end function
end program
