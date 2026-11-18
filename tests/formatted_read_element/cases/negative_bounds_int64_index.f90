program main
implicit none
integer::u=27,ios
character(4)::a(-3:-1)
integer(8)::j=-2
a='----'
read(u,'(a)',iostat=ios)a(j)
if(ios/=0)stop 1
print '(a)',a

end program
