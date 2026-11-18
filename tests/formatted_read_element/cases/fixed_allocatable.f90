program main
implicit none
integer::u=27,ios
character(4),allocatable::a(:)
allocate(a(-1:1));a='----'
read(u,'(a)',iostat=ios)a(0)
if(ios/=0)stop 1
print '(a)',a

end program
