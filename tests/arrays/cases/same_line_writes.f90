program probe
implicit none
integer :: a(2)
a(1)=1; a(2)=2; a(1)=a(2)+3; print *,a(1),a(2)
end program probe
