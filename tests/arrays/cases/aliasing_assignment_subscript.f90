program probe
implicit none
integer :: a(2)
a(1)=1
a(2)=7
a(a(1))=2
print *,a(1),a(2)
a(a(1))=a(1)+3
print *,a(1),a(2)
end program probe
