program p
implicit none
integer(8)::a(2,2,2)
a(:,:,1)=reshape([0_8,1_8,2_8,4_8],[2,2])
a(:,:,2)=-8_8
print *,trailz(a)
print *,shape(trailz(a)),kind(trailz(a))
end program p
