program p
implicit none
integer(8)::a(5)=[-1_8,0_8,1_8,2_8,3_8]
print *,shiftr(a(5:1:-2),1)
end program
