program p
implicit none
integer::a(3)
a=cshift(make(),1)
print *, "PASS"
contains
function make() result(r)
integer::r(3)
print *,"leak"
r=1
end function
end program
