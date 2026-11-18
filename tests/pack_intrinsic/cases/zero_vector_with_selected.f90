program main
implicit none
integer :: a(1)=[1],v(0)
print *,size(pack(a,.true.,v))
end program
