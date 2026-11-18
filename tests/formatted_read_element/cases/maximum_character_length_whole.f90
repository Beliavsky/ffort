program main
implicit none
integer::u=27,ios
character(65536)::a(1)
read(u,'(a)',iostat=ios)a(1)
if(ios/=0)stop 1
if(trim(a(1))/='xy')stop 2
if(len(a)/=65536)stop 3
print '(a)','OK'
end program
