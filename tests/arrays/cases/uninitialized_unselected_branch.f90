program probe
implicit none
integer :: a(2)
a(1)=11
if(.false.) then
 print *,a(2)
end if
print *,a(1)
end program probe
