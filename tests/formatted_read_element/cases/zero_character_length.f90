program main
implicit none
integer::u=27,ios
character(0)::a(2)
character(4)::s
read(u,'(a)',iostat=ios)a(2)
if(ios/=0)stop 1
if(len(a)/=0)stop 2
read(u,'(a)',iostat=ios)s
if(ios/=0)stop 1
print '(a)',s

end program
