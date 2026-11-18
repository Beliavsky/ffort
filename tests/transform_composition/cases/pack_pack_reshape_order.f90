program main
implicit none
integer::a(6)=[1,2,3,4,5,6]
print *,pack(reshape(a,[2,3],order=[2,1]),reshape(a,[2,3],order=[2,1])>2)
end program
