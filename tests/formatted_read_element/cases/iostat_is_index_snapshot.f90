program main
implicit none
integer::u=27,ios
character(2)::a(3)
a='--';ios=2
read(u,'(a)',iostat=ios)a(ios)
if(ios/=0)stop 1
print '(a)',a

end program
