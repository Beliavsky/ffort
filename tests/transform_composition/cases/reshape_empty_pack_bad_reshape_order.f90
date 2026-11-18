program p
implicit none
integer::a(4),o(2)
a=1;o=[1,1]
print *,size(pack(reshape(a,[2,2],order=o),.false.))
end program
