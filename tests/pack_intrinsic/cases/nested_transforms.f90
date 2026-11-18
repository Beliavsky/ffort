program main
implicit none
integer :: a(5)=[1,2,3,4,5]
print *, sum(pack(a,a>2)),pack(pack(a,a>1),[.true.,.false.,.true.,.false.])
end program
