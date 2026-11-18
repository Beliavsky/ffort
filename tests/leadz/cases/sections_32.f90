program p
implicit none
integer(4)::a(4)
a=[0_4,1_4,2_4,4_4]
print *,leadz(a(4:1:-1))
end program
