! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
module m
implicit none
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=max(n,0)
end function
impure elemental integer function tick(x) result(v)
integer,intent(in)::x
integer::calls=0
calls=calls+1
v=x+calls
end function
subroutine work(n)
integer,intent(in)::n
integer::a(span(n))
integer,save::runs=0
runs=runs+1
a=10
a=tick(a)
where(a>11) a=a*2
print *,runs,size(a),sum(a),count(a>20)
end subroutine
end module
program main
use m
implicit none
call work(3)
call work(0)
call work(2)
print *,tick(0)
end program
