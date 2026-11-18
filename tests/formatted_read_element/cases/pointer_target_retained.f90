program main
implicit none
integer::u=27,ios
character(4),target::a(2)
character(4),pointer::p(:)
p=>a
read(u,'(a)',iostat=ios)p(1)

end program
