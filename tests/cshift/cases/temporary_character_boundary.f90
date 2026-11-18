program p
implicit none
integer::n
character(len=4096)::a(2048)
n=2048
a=cshift(make(n),1)
if(any(a/="x")) error stop 1
print *, "PASS"
contains
function make(n) result(r)
integer,intent(in)::n
character(len=4096)::r(n)
r="x"
end function
end program
