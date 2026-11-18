program p
implicit none
integer::a(3)
a=cshift(make(),1)
print *, "PASS"
contains
function make() result(r)
integer::r(3)
integer,save::n=0
n=n+1
r=n
end function
end program
