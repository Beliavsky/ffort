program p
implicit none
integer,parameter::sp=kind(1.0),dp=kind(1d0)
real(sp)::aa(2)=[16777217.0_sp,16777216.0_sp]
real(dp)::bb(2)=[16777217.0_dp,16777216.0_dp]
print *,aa(1)-aa(2),bb(1)-bb(2),kind(aa),kind(bb)
end program p
