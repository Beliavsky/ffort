program array_sections
implicit none
integer :: a(-2:4), i, lo=0, hi=4, step=2
do i=-2,4
    a(i)=i
end do
print *, a(lo:hi:step)
a(-1:4)=a(-2:3)
print *, a
a=a(4:-2:-1)
print *, a
a(-2:4:2)=10
print *, a
end program array_sections
