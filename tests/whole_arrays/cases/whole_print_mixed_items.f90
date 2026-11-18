program probe
implicit none
integer :: a(-1:1)
a(-1)=2
a(0)=3
a(1)=4
print *, 'start',a,'middle',a+1,'end'
end program probe
