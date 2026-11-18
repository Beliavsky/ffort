program p
implicit none
logical :: x(3)
integer :: i
print *,kind(count(x)),kind(count(x,kind=8)),kind(all(x)),kind(any(x))
print *,kind(dble(i)),kind(merge(i,0,.true.))
end program
