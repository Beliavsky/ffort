program p
implicit none
integer::n,v
n=500001
v=sum(cshift(make(n),1))
print *, "PASS"
contains
function make(n) result(r)
integer,intent(in)::n
integer::r(n)
r=1
end function
end program
