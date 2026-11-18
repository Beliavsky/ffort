program main
implicit none
integer::u=27,ios
character(2)::a(3)
integer::i
do i=1,3
read(u,'(a)',iostat=ios)a(i)
if(ios/=0)stop 1
end do
print '(a)',a

end program
