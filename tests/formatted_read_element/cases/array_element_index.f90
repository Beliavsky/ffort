program main
implicit none
integer::u=27,ios
character(2)::a(3)
integer::idx(2)=[3,1]
a='--'
read(u,'(a)',iostat=ios)a(idx(1))
if(ios/=0)stop 1
print '(a)',a

end program
