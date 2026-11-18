program main
implicit none
integer::u=27,ios
character(:),allocatable::a(:)
allocate(character(4)::a(-1:0));a='----'
read(u,'(a)',iostat=ios)a(0)
if(ios/=0)stop 1
if(len(a)/=4)stop 2
print '(a)',a

end program
