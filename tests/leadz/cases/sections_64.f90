program p
implicit none
integer(8)::a(4)
a=[0_8,1_8,2_8,4_8]
print *,leadz(a(4:1:-1))
end program
