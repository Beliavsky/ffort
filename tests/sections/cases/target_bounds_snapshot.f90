program probe
implicit none
integer :: a(1:5)
a(1)=2
a(2)=4
a(3)=9
a(4)=8
a(5)=7
a(a(1):a(2))=6
print *, a
end program probe
