program array_intrinsic_oracle
implicit none
integer :: aa(3),ss
logical :: mm(3)
print *,111
aa=1
mm=.true.
ss=0
print *,sum(aa,mm(::ss))
end program
