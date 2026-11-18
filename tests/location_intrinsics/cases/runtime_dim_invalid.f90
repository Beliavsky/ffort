program p
implicit none
integer::d
d=3
print *,minloc(reshape([1,2],[1,2]),d)
end program
