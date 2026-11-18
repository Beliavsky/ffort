program p
implicit none
integer(4)::a(2,2,2)
a(:,:,1)=reshape([0_4,1_4,2_4,4_4],[2,2])
a(:,:,2)=-8_4
print *,trailz(a)
print *,shape(trailz(a)),kind(trailz(a))
end program p
