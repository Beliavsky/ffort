program probe
implicit none
integer :: a(3)
a=2147483647
a(1:3:2)=a(1:3:2)+1
end program probe
