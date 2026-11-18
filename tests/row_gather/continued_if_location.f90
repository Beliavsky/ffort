program p
implicit none
integer::x
x=0
if(.true.) &
 x=3
if(.false.) &
 x=4
print *,x
end program
