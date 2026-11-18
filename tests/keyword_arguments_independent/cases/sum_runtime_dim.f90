program keyword_oracle
implicit none
integer :: aa(2,3),dd
logical :: mm(2,3)
aa=2
mm=.true.
dd=2
print *,sum(mask=mm,array=aa,dim=dd)
end program
