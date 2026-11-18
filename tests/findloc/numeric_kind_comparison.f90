program p
implicit none
integer(8)::a(4)=[9007199254740992_8,9007199254740993_8,2_8,2_8]
real(8)::r(4)=[0.1_8,0.5_8,1.5_8,0.5_8]
print *,findloc(a,9007199254740993_8),findloc(a,2,1,kind=8,back=.true.)
print *,findloc(r,0.5,dim=1,back=.true.),findloc(r,0.1,dim=1)
end program
