program p
implicit none
real(8)::aa(-1:2),bb(2,3)
print *,kind(aa),kind(bb),kind(aa(2:1)),kind(bb(1,:))
end program p
