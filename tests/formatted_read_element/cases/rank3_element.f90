program main
implicit none
integer::u=27,ios
character(2)::a(1:2,-2:-1,3:4)
integer::i,j,k
a='--'
read(u,'(a)',iostat=ios)a(1,-1,4)
if(ios/=0)stop 1
do k=3,4
do j=-2,-1
do i=1,2
print '(a)',a(i,j,k)
end do
end do
end do

end program
