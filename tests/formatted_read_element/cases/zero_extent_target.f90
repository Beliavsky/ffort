program main
implicit none
integer::u=27,ios
character(2),allocatable::a(:)
integer::j=1
allocate(a(0))
read(u,'(a)',iostat=ios)a(j)

end program
