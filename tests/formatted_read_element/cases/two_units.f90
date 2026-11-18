program main
implicit none
integer::u=27,ios
character(2)::a(3)
read(u,'(a)',iostat=ios)a(1)
if(ios/=0)stop 1
u=28
read(u,'(a)',iostat=ios)a(2)
if(ios/=0)stop 1
u=27
read(u,'(a)',iostat=ios)a(3)
if(ios/=0)stop 1
print '(a)',a

end program
