program probe
implicit none
integer :: a(1:5)
a(1)=2
a(2)=10
a(3)=20
a(4)=30
a(5)=40
a(1:5:a(1))=a(1:5:a(1))+1
print *, a
end program probe
