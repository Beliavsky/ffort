program main
implicit none
integer :: a(2)=[1,2]
logical :: m(2)
print *,size(pack(a,m))
end program
