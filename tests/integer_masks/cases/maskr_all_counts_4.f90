program p
implicit none
integer :: n
do n=0,32
print *,maskr(n,kind=4)
end do
end program
