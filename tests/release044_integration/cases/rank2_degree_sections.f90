program p
implicit none
real(8)::angles(2,2),values(2,2)
character(24)::fmt
integer::i
angles=reshape([30d0,90d0,150d0,-90d0],[2,2])
values=sind(angles)
fmt='(*(f5.1))'
print fmt,(values(i,:),i=2,1,-1)
end program
