program main
implicit none
integer::u=27,ios
character(4)::a(3)
integer::j=1
a='----'
read(u,'(a)',iostat=ios)a(max(j,1)+1)
if(ios/=0)stop 1
print '(a)',a

end program
