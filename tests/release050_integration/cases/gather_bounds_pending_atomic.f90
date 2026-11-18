program p

implicit none
integer::a(2,1,1)
character(8)::s(1)
a(:,1,1)=[1,2]
write(*,'(a)',advance='no')'SAFE'
write(s(1),'(i0)')shiftr(a([3],:,:),1)
end program
