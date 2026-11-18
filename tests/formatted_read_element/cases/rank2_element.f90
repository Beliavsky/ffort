program main
implicit none
integer::u=27,ios
character(2)::a(-1:0,3:4)
a='--'
read(u,'(a)',iostat=ios)a(0,4)
if(ios/=0)stop 1
print '(a)',a

end program
