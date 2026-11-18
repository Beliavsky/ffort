program main
implicit none
integer::u=27,ios
character(4)::a(2)
a='----'
call take(u,a,4)
print '(a)',a
contains
subroutine take(unit,x,n)
integer,intent(in)::unit,n
character(n),intent(inout)::x(:)
integer::status
read(unit,'(a)',iostat=status)x(2)
if(status/=0)stop 1
end subroutine
end program
