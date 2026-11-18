program main
implicit none
integer::u=27,ios
character(2)::a(2)
read(u,'(a)',iostat=ios)a(1)
if(ios/=0)stop 1
backspace(u)
read(u,'(a)',iostat=ios)a(2)
if(ios/=0)stop 1
print '(a)',a

end program
