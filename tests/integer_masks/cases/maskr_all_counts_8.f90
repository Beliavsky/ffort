program p
implicit none
integer :: n
do n=0,64
print *,maskr(n,kind=8)
end do
end program
