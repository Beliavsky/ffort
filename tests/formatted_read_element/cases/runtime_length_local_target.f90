program main
implicit none
call take(4)
contains
subroutine take(n)
integer,intent(in)::n
integer::u=27,status
character(n)::a(2)
a='----'
read(u,'(a)',iostat=status)a(2)
if(status/=0)stop 1
print '(a)',a
end subroutine
end program
