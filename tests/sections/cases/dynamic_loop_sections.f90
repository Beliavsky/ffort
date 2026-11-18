program probe
implicit none
integer :: i, j, s
integer :: a(1:5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
do s=-2,2,4
i=3
j=5
print *, a(i:j:s)
print *, a(::s)
end do
end program probe
