program main
implicit none
integer::u=27,ios
character(4)::a(1)
integer(8)::status
read(u,'(a)',iostat=status)a(1)
if(status/=0_8)stop 1
print '(a)',a

end program
