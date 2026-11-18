program main
implicit none
integer::u=27,ios
character(2)::a(1)
do ios=1,2
read(u,'(a)',iostat=ios)a(1)
end do

end program
