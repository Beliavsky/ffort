module m
implicit none
contains
subroutine host(a,n,answer)
integer,intent(inout)::a(:)
integer,intent(in)::n
integer,intent(out)::answer
integer::offset
logical::enabled
real(kind=kind(0d0))::scale
character(len=3)::tag
offset=3
enabled=.true.
scale=2.5d0
tag='abc'
call apply()
call finish()
contains
subroutine apply()
integer::i
if(enabled) then
 do i=1,n
  a(i)=a(i)+offset
 end do
end if
offset=offset+1
scale=scale+0.5d0
tag='xyz'
end subroutine
subroutine finish()
answer=sum(a)+offset
print *,enabled,scale,tag
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::a(3),answer
a=[1,2,3]
call host(a,3,answer)
print *,a,answer
end program
