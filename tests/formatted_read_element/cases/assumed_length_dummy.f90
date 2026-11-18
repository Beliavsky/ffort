program main
implicit none
integer::u=27,ios
character(4)::a(2)
a='----'
call take(u,a)
print '(a)',a
contains
subroutine take(unit,x)
integer,intent(in)::unit
character(*),intent(inout)::x(:)
integer::status
read(unit,'(a)',iostat=status)x(2)
if(status/=0)stop 1
end subroutine
end program
