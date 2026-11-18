program p
implicit none
integer(4)::a(5)=[-1_4,0_4,1_4,2_4,3_4]
print *,shiftr(a(5:1:-2),1)
end program
