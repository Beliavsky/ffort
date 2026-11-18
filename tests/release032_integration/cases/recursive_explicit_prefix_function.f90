! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(6)
integer,pointer::p(:)
a=[1,2,3,4,50,60]
p=>a(6:1:-1)
call fill(a,4)
print *,total(a,4),p,shape(p)
contains
subroutine fill(x,n)
integer,intent(in)::n
integer,target,intent(inout)::x(n)
x=x+n
end subroutine
recursive integer function total(x,n) result(v)
integer,intent(in)::n
integer,intent(in)::x(n)
if(n==0) then
v=0
else
v=x(n)+total(x,n-1)
end if
end function
end program
