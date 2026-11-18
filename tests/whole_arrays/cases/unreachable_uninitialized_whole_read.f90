program probe
implicit none
integer :: a(3), b(3)
if (.false.) then
b=a+1
print *, b
end if
a=2
print *, a
end program probe
