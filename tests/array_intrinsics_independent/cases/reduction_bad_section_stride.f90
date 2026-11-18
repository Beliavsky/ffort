program array_intrinsic_oracle
implicit none
integer :: aa(3),ss
print *,111
aa=1
ss=0
print *,sum(aa(::ss))
end program
