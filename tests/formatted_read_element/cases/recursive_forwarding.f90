program main
implicit none
integer::u=27,ios
character(2)::a(3)
call take(u,a,1)
print '(a)',a
contains
recursive subroutine take(unit,x,i)
integer,intent(in)::unit,i
character(*),intent(inout)::x(:)
integer::status
read(unit,'(a)',iostat=status)x(i)
if(status/=0)stop 1
if(i<size(x))call take(unit,x,i+1)
end subroutine
end program
