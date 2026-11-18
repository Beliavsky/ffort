program p
implicit none
integer::u,ios
character(2)::a(3)
character(:),allocatable::words(:)
u=27
a='--'
allocate(character(2)::words(1))
read(u,'(a)',iostat=ios)a(len(words))
if(ios/=0)stop 1
if(a(1)/='--'.or.a(2)/='xy'.or.a(3)/='--')stop 2
print '(a)',a(2)
end program
