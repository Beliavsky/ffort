program p
implicit none
integer::k
k=8
print *,"NO OUTPUT"
print *,minloc([1,2],kind=k)
end program
