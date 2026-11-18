program main
implicit none
integer :: a(500001)
a=1
print *,size(pack(a,.true.)+pack(a,.true.))
end program
