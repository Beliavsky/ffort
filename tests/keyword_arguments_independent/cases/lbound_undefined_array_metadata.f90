program keyword_oracle
implicit none
integer :: aa(-1:0,4:6)
print *,lbound(array=aa,dim=1)
print *,lbound(dim=1,array=aa)
print *,lbound(aa,dim=1)
print *,lbound(DiM=1,ArRaY=aa)
print *,lbound(array=aa,dim=2)
print *,lbound(dim=2,array=aa)
print *,lbound(aa,dim=2)
print *,lbound(DiM=2,ArRaY=aa)
end program
