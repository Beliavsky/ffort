program probe
implicit none
integer,parameter :: lower=-2, upper=2
integer :: a(lower:upper), i
do i=lower,upper
a(i)=i*i
end do
print*,a(-2),a(0),a(upper)
end program probe
