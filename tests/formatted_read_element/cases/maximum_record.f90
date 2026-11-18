program main
implicit none
integer::u=27,ios
character(2)::a(1)
read(u,'(a)',iostat=ios)a(1)
if(ios/=0)stop 1
print '(a)',a

end program
