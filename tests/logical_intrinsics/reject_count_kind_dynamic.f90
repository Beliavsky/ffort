program p
implicit none
integer::k
k=8
print *,count([.true.],kind=k)
end program
