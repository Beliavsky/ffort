! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
module m
implicit none
integer::offset
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+offset
end function
subroutine driver()
integer,save::n=2
call work(n)
end subroutine
subroutine work(n)
integer,intent(inout)::n
integer::a(span(n))
character(len=span(n))::s
integer,save::runs=0
runs=runs+1
n=n+1
offset=offset+1
a=runs
s='abcde'
print *,n,offset,size(a),len(s),sum(a),runs,s
end subroutine
end module
program main
use m
implicit none
offset=1
call driver()
call driver()
end program
