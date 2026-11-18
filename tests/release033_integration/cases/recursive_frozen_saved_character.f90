! Synthetic release 0.33 composition fixture; original bodies, if any, are separate.
module m
implicit none
contains
pure integer function span(n) result(v)
integer,intent(in)::n
v=n+1
end function
recursive subroutine visit(n)
integer,intent(in)::n
integer::a(span(n))
character(len=span(n))::s
integer,save::visits=0
character(len=3),save::word='abc'
visits=visits+1
a=visits
s=word
word=word(2:)//'x'
if(n>0) call visit(n-1)
print *,n,size(a),sum(a),len(s),s,visits,word
end subroutine
end module
program main
use m
implicit none
call visit(2)
call visit(0)
end program
