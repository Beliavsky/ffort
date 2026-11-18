program keyword_oracle
implicit none
integer :: aa(-1:0,4:6)
print *,ubound(array=aa,dim=1)
print *,ubound(dim=1,array=aa)
print *,ubound(aa,dim=1)
print *,ubound(DiM=1,ArRaY=aa)
print *,ubound(array=aa,dim=2)
print *,ubound(dim=2,array=aa)
print *,ubound(aa,dim=2)
print *,ubound(DiM=2,ArRaY=aa)
end program
